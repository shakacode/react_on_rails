# Streaming Server-Side Rendering

React on Rails Pro supports streaming server rendering using React 18/19's `renderToPipeableStream` API. Instead of waiting for the entire page to render before sending any HTML, streaming SSR sends HTML to the browser progressively as each part of the page becomes ready.

> **Route map**: Start at [React on Rails Pro](./react-on-rails-pro.md) if you're choosing a path. This page is the canonical streaming SSR overview; for the technical implementation guide, see [Streaming Server Rendering](../oss/building-features/streaming-server-rendering.md).

## Why Streaming SSR?

Traditional SSR renders the full page on the server, then sends the complete HTML in one response. This means the user sees nothing until the slowest component finishes rendering. Streaming SSR changes this:

- **Faster Time to First Byte (TTFB)** — The browser receives the page shell immediately
- **Progressive rendering** — Content appears as it becomes ready, not all at once
- **Suspense integration** — React's `<Suspense>` boundaries define which parts can stream independently
- **Selective Hydration** — Components become interactive as soon as their JavaScript loads, even while other parts are still streaming

## How It Works

1. Rails starts the response immediately, sending the HTML shell (layout, static content, loading placeholders)
2. The Node Renderer uses `renderToPipeableStream` to render React components
3. As each `<Suspense>` boundary resolves (e.g., an async data fetch completes), the rendered HTML chunk is streamed to the browser
4. The browser replaces placeholders with real content — no full-page reload needed

```mermaid
sequenceDiagram
    autonumber
    participant Browser
    participant Rails
    participant Renderer as Node Renderer
    Note over Rails: ActionController::Live (ReactOnRailsPro::Stream)
    Browser->>Rails: GET page
    Rails->>Renderer: streaming render request
    Renderer->>Renderer: renderToPipeableStream() — onShellReady
    Renderer-->>Rails: HTML shell chunk
    Rails-->>Browser: shell paints immediately (fast TTFB)
    loop each Suspense boundary resolves
        Renderer-->>Rails: length-prefixed HTML chunk
        Rails-->>Browser: append chunk — progressive paint + selective hydration
    end
```

## Prerequisites

- React on Rails Pro
- React 19
- React on Rails v16.0.0 or higher
- Node Renderer running (streaming requires Node.js, not ExecJS)
- For async props (streaming each slow prop independently): React Server Components enabled — `config.enable_rsc_support = true`

## Progressive Data with Async Props

Streaming SSR sends HTML as React renders it. **Async props** (a React Server Components feature, so it requires `enable_rsc_support`) go one step further: Rails emits each prop _as its data becomes ready_ and forwards the matching Suspense boundary to the browser the moment it resolves.

This is the recommended answer to "my component needs Rails data during render": **Rails owns the data and pushes it in**, preserving your controller / model / authorization / caching layers — the renderer never has to call back into Rails.

> [!NOTE]
> A Server Component _can_ `fetch` a Rails API directly, but the renderer's VM has no `fetch`, `Headers`, `Request`, or `Response` by default — you must bundle an HTTP client or inject them via `additionalContext` — and doing so bypasses Rails' auth and caching. `'use server'` Server Actions are **not** supported (the renderer has no DB/session/cookie access). Prefer props / async props. See [RSC data fetching patterns](../oss/migrating/rsc-data-fetching.md).

Under the hood, Rails opens a bidirectional HTTP/2 NDJSON stream to the renderer and feeds props in as it resolves them. Each update runs in that request's isolated `sharedExecutionContext` and resolves a Promise, which lets React flush the corresponding HTML back to Rails for forwarding to the browser:

```mermaid
sequenceDiagram
    autonumber
    participant Browser
    participant Rails
    participant Renderer as Node Renderer
    Note over Renderer: per-request sharedExecutionContext (isolated)
    Browser->>Rails: GET page
    Rails->>Renderer: open incremental-render NDJSON stream<br/>first line: renderingRequest
    Renderer->>Renderer: render begins — a Server Component awaits getReactOnRailsAsyncProp('users')
    Renderer-->>Rails: HTML shell + Suspense fallbacks
    Rails-->>Browser: stream shell + fallbacks
    loop each prop resolves in Rails (emit.call)
        Rails->>Renderer: NDJSON updateChunk — resolve async-prop Promise
        Renderer->>Renderer: Promise resolves in sharedExecutionContext — React continues
        Renderer-->>Rails: flush that boundary's HTML
        Rails-->>Browser: append boundary HTML
    end
    Rails->>Renderer: close stream (END_STREAM)
    Renderer->>Renderer: reject any unresolved async props
```

The view helper is `stream_react_component_with_async_props`, which yields an emitter:

```erb
<%= stream_react_component_with_async_props("Dashboard") do |emit|
      emit.call("users", User.active.limit(50).as_json(only: [:id, :name]))
      emit.call("posts", Post.recent.limit(20).as_json(only: [:id, :title]))
    end %>
```

For the full data-fetching guidance — synchronous props, parallelizing independent queries, and React Query / SWR interop — see [RSC data fetching patterns](../oss/migrating/rsc-data-fetching.md).

### The discouraged alternative: direct `fetch` from the renderer

For contrast, a Server Component _can_ reach Rails by calling `fetch` itself. This is a plain **network round-trip** — the renderer's VM has no in-process access to Rails models, sessions, or cookies — and it gives up what async props provide for free, so prefer async props for Rails-owned data:

```mermaid
sequenceDiagram
    autonumber
    participant Renderer as Node Renderer VM
    participant Rails as Rails API
    participant Data as Rails data layer
    Note over Renderer: discouraged — see caveats below
    Renderer->>Rails: fetch('/api/...') — network hop, not in-process access
    Rails->>Data: handle request (auth, cache, services, database)
    Data-->>Rails: JSON-ready data
    Rails-->>Renderer: JSON
    Renderer->>Renderer: continue rendering
```

Caveats: `fetch`, `Headers`, `Request`, `Response`, `AbortController`, and `AbortSignal` are **not** in the VM by default (bundle an HTTP client or inject them via [runtime globals](../oss/building-features/node-renderer/js-configuration.md#runtime-globals-for-ssr-and-rsc)); cookies, auth, session, and CSRF are **not** forwarded automatically; and it bypasses Rails' authorization and caching layers.

## Implementation Steps

> **This example uses async props**, which build on React Server Components. Enable RSC before you start: set `config.enable_rsc_support = true` in your React on Rails Pro configuration (see the [RSC tutorial](./react-server-components/tutorial.md)). Without it, the `async function` server component won't render and `stream_react_component_with_async_props` raises `ReactOnRailsPro::Error`. If all your data is fast and you don't need progressive streaming, you can skip RSC and use the synchronous [`stream_react_component`](../oss/migrating/rsc-data-fetching.md#data-fetching-in-react-on-rails-pro) with all props passed at once (no `enable_rsc_support` required).

### 1. Use React 19

Ensure you're using React 19 in your `package.json`:

```json
"dependencies": {
  "react": "19.0.4",
  "react-dom": "19.0.4"
}
```

> Note: Use the latest React 19 patch release that is compatible with your app and tooling.

### 2. Prepare Your React Components

For a Suspense boundary to actually stream — show a fallback first, then swap in real content — something inside it must suspend on a Promise. In React on Rails, that data still comes from Rails: with **async props**, Rails sends the fast props immediately and emits each slow prop as it resolves. React on Rails Pro injects a `getReactOnRailsAsyncProp` helper into the root component's props (alongside the `props:` you pass) — you don't import or create it. Calling it returns a Promise for the named async prop; an async child `await`s that Promise inside a `<Suspense>` boundary.

```jsx
// app/javascript/components/MyStreamingComponent.jsx
import React, { Suspense } from 'react';

// Async Server Component (requires RSC — see callout above). Awaits the
// streamed `posts` prop, then renders.
async function PostList({ posts }) {
  const resolved = await posts;
  return (
    <ul>
      {resolved.map((post) => (
        <li key={post.id}>{post.title}</li>
      ))}
    </ul>
  );
}

const MyStreamingComponent = ({ greeting, getReactOnRailsAsyncProp }) => {
  // Returns a Promise that resolves when Rails emits the `posts` prop.
  const postsPromise = getReactOnRailsAsyncProp('posts');

  return (
    <>
      <header>
        <h1>{greeting}</h1>
      </header>
      <Suspense fallback={<div>Loading posts...</div>}>
        <PostList posts={postsPromise} />
      </Suspense>
    </>
  );
};

export default MyStreamingComponent;
```

> **React on Rails note:** Database queries, authentication, authorization, and caching all stay on the Rails side — the controller and view own them. Async props just let Rails emit each result the moment it has it, instead of blocking the whole render on the slowest source. The component never fetches data directly. In TypeScript, type the root component's props with `WithAsyncProps<AsyncProps, SyncProps>` from `react-on-rails-pro`, and type each async child's prop as a `Promise` (e.g. `posts: Promise<Post[]>`) — `getReactOnRailsAsyncProp` returns a Promise, not the resolved value. See [Data Fetching in React on Rails Pro](../oss/migrating/rsc-data-fetching.md#data-fetching-in-react-on-rails-pro) for the prop-based data model this builds on.

> **Handle failures:** if a prop's query rejects, the `await` throws inside the async component and React propagates it up the tree. In production, wrap each `<Suspense>` in an error boundary so a single failed source degrades to a fallback instead of breaking the whole render. React does not ship an `ErrorBoundary` — use the [`react-error-boundary`](https://github.com/bvaughn/react-error-boundary) package (or your own class component):
>
> ```jsx
> import { ErrorBoundary } from 'react-error-boundary';
>
> <ErrorBoundary fallback={<div>Posts unavailable</div>}>
>   <Suspense fallback={<div>Loading posts...</div>}>
>     <PostList posts={postsPromise} />
>   </Suspense>
> </ErrorBoundary>;
> ```

With `auto_load_bundle` enabled (recommended), `MyStreamingComponent` is registered automatically. Otherwise, register it as a server component — server components use `registerServerComponent`, **not** `ReactOnRails.register`:

```js
// Server bundle — bundles the actual component code
import registerServerComponent from 'react-on-rails-pro/registerServerComponent/server';
import MyStreamingComponent from '../components/MyStreamingComponent';

registerServerComponent({ MyStreamingComponent });
```

```js
// Client bundle — registers by name; the component code stays out of the client bundle
import registerServerComponent from 'react-on-rails-pro/registerServerComponent/client';

registerServerComponent('MyStreamingComponent');
```

See [Create a React Server Component](./react-server-components/create-without-ssr.md#register-the-react-server-component-page) for the full registration and RSC bundle setup.

### 3. Add The Component To Your Rails View

Use `stream_react_component_with_async_props`. Fast props go in `props:`; each `emit.call(name, value)` streams one more prop to the browser as soon as it resolves. Run the slow query **inside the block** — that's what lets the shell render first and the prop stream in afterward. (Loading it in the controller before this helper would block the shell until the query finished, defeating the point of async props.) Keep the block thin: call a model scope or query object, not business logic.

```erb
<!-- app/views/example/show.html.erb -->

<%= stream_react_component_with_async_props('MyStreamingComponent',
      props: { greeting: 'Hello, Streaming World!' }) do |emit|
  # Runs in the streaming flow: the shell (greeting + Suspense fallback) is
  # sent first, then this emits `posts` once the query resolves. Rails still
  # owns the query, auth, and caching — `Post.recent` is a model scope.
  emit.call('posts', Post.recent.limit(20).as_json(only: [:id, :title]))
end %>

<footer>
  <p>Footer content</p>
</footer>
```

> If every data source is fast, use the simpler `stream_react_component` and pass all props synchronously — React still streams the rendered HTML to the browser as it walks the tree. Reach for async props when one or more sources are slow. See [Data Fetching in React on Rails Pro](../oss/migrating/rsc-data-fetching.md#data-fetching-in-react-on-rails-pro).

### 4. Render The View Using The `stream_view_containing_react_components` Helper

Ensure you have a controller that renders the view containing the React components. The controller must include the `ReactOnRails::Controller` and `ReactOnRailsPro::Stream` modules.

```ruby
# app/controllers/example_controller.rb

class ExampleController < ApplicationController
  include ReactOnRails::Controller
  include ReactOnRailsPro::Stream
  # Note: ActionController::Live is already mixed in by ReactOnRailsPro::Stream,
  # but you can include it explicitly if you prefer.

  def show
    stream_view_containing_react_components(template: 'example/show')
  end
end
```

The controller just renders — the async prop's query runs in the view's `emit` block (Step 3) so the shell can stream before the query finishes. The controller still owns request-level concerns: authentication, authorization, and any fast props you pass synchronously.

#### Loading Multiple Slow Sources in Parallel

When several sources are slow and independent, run them concurrently with the [`async` gem](https://github.com/socketry/async) (already a dependency of React on Rails Pro and loaded by the streaming helper). Pro's streaming stack is fiber-based, so fan out with fibers from the running reactor rather than introducing a separate Ruby-thread concurrency model. The emit block runs inside an `Async` task — capture it with `Async::Task.current` and spawn one child task per source with `parent.async`, so each prop is emitted the moment its own query resolves:

```erb
<%= stream_react_component_with_async_props('Dashboard',
      props: { title: 'Dashboard' }) do |emit|
  parent  = Async::Task.current
  user_id = current_user.id # capture request state before fanning out

  # Each task runs its query concurrently and emits its prop as soon as that
  # query resolves — the slowest source no longer blocks the others.
  tasks = [
    parent.async { emit.call('posts', Post.for_user(user_id).recent.limit(20).as_json(only: [:id, :title])) },
    parent.async { emit.call('stats', DashboardStats.for(user_id).as_json(only: [:metric, :value])) },
    parent.async { emit.call('feed',  FeedService.for(user_id).as_json(only: [:id, :title])) },
  ]
  tasks.each(&:wait) # block stays open until each task finishes
end %>
```

On the React side, give each async prop its own `<Suspense>` boundary (as in Step 2) so each section streams in independently as its query finishes.

> **Error handling — two distinct failure modes:**
>
> - An error raised in the task **body before `emit.call`** (e.g. a query raising `ActiveRecord::StatementInvalid`) propagates through `wait` and closes the stream, so the remaining props may not be sent. If one source failing shouldn't cut off the others, wrap each task body in a `rescue` and emit a fallback (or skip that prop).
> - An error raised **inside `emit.call`** (a non-serializable value, a write failure) may be swallowed by the emitter — logged rather than re-raised — so the task completes normally and `wait` sees nothing, yet the prop is never delivered and its `<Suspense>` boundary never resolves. Pass only JSON-serializable values (e.g. `.as_json(only: [...])`) to `emit.call` to avoid a silently hanging boundary.

**Requirements and footguns for concurrent async props:**

- **`config.active_support.isolation_level = :fiber`** (Rails 7.0.2+) — without it, fibers share one connection and concurrent queries corrupt each other; with it, each fiber checks out its own pooled connection.
- **Connection pool size** — must cover the total DB-using fibers in flight across _all_ concurrent requests, not just this one fan-out, or extra fibers block on checkout.
- **Driver matters** — queries only truly overlap on a fiber-scheduler-aware driver such as `pg` (PostgreSQL). Blocking drivers like `mysql2` and `sqlite3` serialize on the reactor, so the fan-out gives no speedup.
- **Capture request state before fanning out** — read `current_user.id` (and any other `CurrentAttributes`) into locals _before_ `parent.async`. Per-fiber isolation does not copy `CurrentAttributes` into child tasks, and this fails silently as stale/missing data rather than an error.
- **Reactor-only** — `Async::Task.current` only works inside the `emit` block (which runs in Pro's reactor). Don't copy this fan-out into a plain controller action, background job, or test that hasn't started an Async reactor — it raises `Async::Error`.

> **Note:** Running queries concurrently this way relies on ActiveRecord and your database driver supporting fiber scheduling (non-blocking I/O under a `Fiber.scheduler`). Confirming and configuring that for your stack — adapter choice, gem versions, connection settings — is your responsibility and outside the scope of this guide. If fiber scheduling isn't in place, the queries still run correctly, just serialized rather than in parallel.

### 5. Test Your Application

You can test your application by running `rails server` and navigating to the appropriate route.

### Error Handling Note for React on Rails Pro 16.7

React on Rails Pro 16.7 reports streaming renderer failures as `ReactOnRailsPro::Error` during chunk iteration.
That includes unreadable response statuses and readable HTTP error statuses delivered as streaming bodies. If
your code directly iterates a stream from `render_code_as_stream`, wrap `each_chunk` in normal error handling and
treat that exception as a renderer failure. Older releases could return no chunks for these responses, so custom
callers should not use an empty stream as a success signal.

### 6. What Happens During Streaming

`stream_react_component_with_async_props` uses React's `renderToPipeableStream` to stream the shell first, then streams each async prop as Rails emits it:

1. React renders everything outside the unresolved `<Suspense>` boundaries and streams that shell immediately — the header and footer appear, with the `Loading posts...` fallback in place
2. When Rails runs `emit.call('posts', ...)`, the resolved value streams to the renderer and the `posts` Promise resolves
3. The async `PostList` awaits that Promise, renders, and React streams the post-list HTML chunk that replaces the fallback

For example, with our `MyStreamingComponent`, the sequence is:

1. The browser receives the shell immediately, including the Suspense fallback:

```html
<header>
  <h1>Hello, Streaming World!</h1>
</header>
<template id="s0">
  <div>Loading posts...</div>
</template>
<footer>
  <p>Footer content</p>
</footer>
```

2. Once Rails emits `posts` and `PostList` resolves, its rendered HTML streams to the browser:

```html
<template hidden id="b0">
  <ul>
    <li>First Post</li>
    <li>Second Post</li>
  </ul>
</template>

<script>
  // This implementation is slightly simplified
  document.getElementById('s0').replaceChildren(document.getElementById('b0'));
</script>
```

To render more of the page progressively, add an async prop and a `<Suspense>` boundary for each slow section — emit each one from the block as Rails resolves it, and every boundary streams in independently. This keeps the whole page in a single component tree (shared layout, context, and props) rather than splitting it across multiple `stream_react_component` calls.

## Compression Middleware Compatibility

Streaming responses use `ActionController::Live`, which writes chunks to a `SizedQueue` (a destructive, non-idempotent data structure). Standard Rack compression middleware (`Rack::Deflater`, `Rack::Brotli`) works correctly with streaming **by default** — each chunk is compressed and flushed immediately, preserving low TTFB.

However, if you pass an `:if` condition that calls `body.each` to check the response size, **streaming responses will deadlock**. The `:if` callback destructively consumes all chunks from the queue, leaving nothing for the compressor to read.

```ruby
# BAD — causes deadlocks with streaming responses
config.middleware.use Rack::Deflater, if: lambda { |*, body|
  sum = 0
  body.each { |i| sum += i.length }  # destructive — drains the queue
  sum > 512
}
```

The [Rack SPEC](https://github.com/rack/rack/blob/main/SPEC.rdoc) states that `each` must only be called once and middleware must not call `each` directly unless the body responds to `to_ary`. Streaming bodies explicitly do not support `to_ary`.

**Correct pattern** — check `to_ary` before iterating:

```ruby
config.middleware.use Rack::Deflater, if: lambda { |*, body|
  # Streaming bodies don't support to_ary — always compress them.
  # Rack::Deflater handles streaming correctly with sync flush per chunk.
  return true unless body.respond_to?(:to_ary)

  body.to_ary.sum(&:bytesize) > 512
}
```

The same applies to `Rack::Brotli` or any middleware that accepts an `:if` callback.

## Metadata with Streaming

Streaming SSR is fully compatible with React 19's native metadata tags. You can render `<title>`, `<meta>`, and `<link>` anywhere in your component tree — including inside async components within Suspense boundaries — and React will hoist them into the document `<head>`.

This is a significant advantage over `react-helmet`, which requires `renderToString` and is incompatible with streaming. For details, see [React 19 Native Metadata](../oss/building-features/react-19-native-metadata.md).

## When to Use Streaming

Streaming SSR is particularly valuable in specific scenarios. Here's when to consider it:

### Ideal Use Cases

1. **Data-Heavy Pages**
   - Pages that fetch data from multiple sources
   - Dashboard-style layouts where different sections can load independently
   - Content that requires heavy processing or computation

2. **Progressive Enhancement**
   - When you want users to see and interact with parts of the page while others load
   - For improving perceived performance on slower connections
   - When different parts of your page have different priority levels

3. **Large, Complex Applications**
   - Applications with multiple independent widgets or components
   - Pages where some content is critical and other content is supplementary
   - When you need to optimize Time to First Byte (TTFB)

### Best Practices for Streaming

1. **Component Structure**

   ```jsx
   // Good: Independent sections that can stream separately
   <Layout>
     <Suspense fallback={<HeaderSkeleton />}>
       <Header />
     </Suspense>
     <Suspense fallback={<MainContentSkeleton />}>
       <MainContent />
     </Suspense>
     <Suspense fallback={<SidebarSkeleton />}>
       <Sidebar />
     </Suspense>
   </Layout>

   // Bad: Everything wrapped in a single Suspense boundary
   <Suspense fallback={<FullPageSkeleton />}>
     <Header />
     <MainContent />
     <Sidebar />
   </Suspense>
   ```

2. **Data Loading Strategy**
   - Prioritize critical data that should be included in the initial HTML
   - Use streaming for supplementary data that can load progressively
   - Consider implementing a waterfall strategy for dependent data

## Script Loading Strategy for Streaming

**IMPORTANT**: When using streaming server rendering, you should NOT use `defer: true` for your JavaScript pack tags. Here's why:

### Understanding the Problem with Defer

Deferred scripts (`defer: true`) only execute after the entire HTML document has finished parsing and streaming. This defeats the key benefit of React's Selective Hydration feature, which allows streamed components to hydrate as soon as they arrive—even while other parts of the page are still streaming.

**Example Problem:**

```erb
<!-- ❌ BAD: This delays hydration for ALL streamed components -->
<%= javascript_pack_tag('client-bundle', defer: true) %>
```

With `defer: true`, your streamed components will:

1. Arrive progressively in the HTML stream
2. Be visible to users immediately
3. But remain non-interactive until the ENTIRE page finishes streaming
4. Only then will they hydrate

### Recommended Approaches

**For Pages WITH Streaming Components:**

```erb
<!-- ✅ GOOD: No defer - allows Selective Hydration to work -->
<%= javascript_pack_tag('client-bundle', 'data-turbo-track': 'reload', defer: false) %>

<!-- ✅ BEST: Use async for even faster hydration (requires Shakapacker ≥ 8.2.0) -->
<%= javascript_pack_tag('client-bundle', 'data-turbo-track': 'reload', async: true) %>
```

**For Pages WITHOUT Streaming Components:**

With Shakapacker ≥ 8.2.0, `async: true` is recommended even for non-streaming pages to improve Time to Interactive (TTI):

```erb
<!-- ✅ RECOMMENDED: Use async for optimal performance -->
<%= javascript_pack_tag('client-bundle', 'data-turbo-track': 'reload', async: true) %>
```

Note: With React on Rails Pro, `async: true` allows components to hydrate during page load, improving TTI even without streaming. See the Early Hydration section below for details.

**⚠️ Important: Redux Shared Store Caveat**

If you are using Redux shared stores with the `redux_store` helper and **inline script registration** (registering components in view templates with `<script>ReactOnRails.register({ MyComponent })</script>`), you must use `defer: true` instead of `async: true`:

```erb
<!-- ⚠️ REQUIRED for Redux shared stores with inline registration -->
<%= javascript_pack_tag('client-bundle', 'data-turbo-track': 'reload', defer: true) %>
```

**Why?** With `async: true`, the bundle executes immediately upon download, potentially **before** inline `<script>` tags in the HTML execute. This causes component registration failures when React on Rails tries to hydrate the component.

**Solutions:**

1. **Use `defer: true`** - Ensures proper execution order (inline scripts run before bundle)
2. **Move registration to bundle** - Register components in your JavaScript bundle instead of inline scripts (recommended)
3. **Use React on Rails Pro** - Pro's `getOrWaitForStore` and `getOrWaitForStoreGenerator` can handle async loading with inline registration

See the [Redux Store API documentation](../oss/api-reference/redux-store-api.md) for more details on Redux shared stores.

### Why Async is Better Than No Defer

With Shakapacker ≥ 8.2.0, using `async: true` provides the best performance:

- **No defer/async**: Scripts block HTML parsing and streaming
- **defer: true**: Scripts wait for complete page load (defeats Selective Hydration)
- **async: true**: Scripts load in parallel and execute ASAP, enabling:
  - Selective Hydration to work immediately
  - Components to become interactive as they stream in
  - Optimal Time to Interactive (TTI)

### Migration Timeline

1. **Before Shakapacker 8.2.0**: Use `defer: false` for streaming pages
2. **Shakapacker ≥ 8.2.0**: Migrate to `async: true` for all pages (streaming and non-streaming)
3. **Early Hydration (Pro)**: Pro hydrates components early for optimal Time to Interactive — no additional configuration needed (see section below)

## Early Hydration (Pro)

React on Rails Pro hydrates components during the page loading state (before `DOMContentLoaded`), rather than waiting for the full page load. This works optimally with `async: true` scripts and is always on for Pro — there is no configuration toggle.

**Benefits of early hydration with `async: true`:**

- Components become interactive as soon as their JavaScript loads
- No need to wait for `DOMContentLoaded` or full-page load
- Optimal Time to Interactive (TTI) for both streaming and non-streaming pages
- Works seamlessly with React's Selective Hydration

**Note:** Early hydration requires a React on Rails Pro license. It is always enabled for Pro users and unavailable in OSS — no per-component toggle is exposed.

**generated_component_packs_loading_strategy Option:**

This configuration option sets the default loading strategy for auto-generated component packs:

- `:async` (recommended for Shakapacker ≥ 8.2.0) - Scripts load asynchronously
- `:defer` - Scripts defer until page load completes
- `:sync` - Scripts load synchronously (blocks page rendering)

```ruby
ReactOnRails.configure do |config|
  config.generated_component_packs_loading_strategy = :async
end
```

## Further Reading

- [Node Renderer](./node-renderer.md) — Required for streaming SSR
- [React 19 Native Metadata](../oss/building-features/react-19-native-metadata.md) — Metadata hoisting with streaming
- [React Server Components](./react-server-components/tutorial.md) — RSC builds on streaming SSR for even more advanced rendering
