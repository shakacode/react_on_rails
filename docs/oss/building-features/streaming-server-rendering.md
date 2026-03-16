# Streaming Server Rendering with React 18

> **Pro Feature** — SSR works in the OSS version via mini_racer.
> Pro adds streaming SSR with `renderToPipeableStream` and Suspense for progressive rendering. [Learn more →](https://pro.reactrails.com)

React on Rails Pro supports streaming server rendering using React 18's latest APIs, including `renderToPipeableStream` and Suspense. This guide explains how to implement and optimize streaming server rendering in your React on Rails application.

## Prerequisites

- React on Rails Pro subscription
- React 19
- React on Rails v16.0.0 or higher
- React on Rails Pro v4.0.0.rc.5 or higher

## Benefits of Streaming Server Rendering

- Faster Time to First Byte (TTFB)
- Progressive page loading
- Improved user experience
- Better SEO performance
- Optimal handling of data fetching

## Implementation Steps

1. **Use React 19 Version**

First, ensure you're using React 19 in your package.json:

```json
"dependencies": {
  "react": "19.0.0",
  "react-dom": "19.0.0"
}
```

> Note: Check the React documentation for the latest release that supports streaming.

2. **Prepare Your React Components**

You can create async React components that return a promise. Then, you can use the `Suspense` component to render a fallback UI while the component is loading.

```jsx
// app/javascript/components/MyStreamingComponent.jsx
import React, { Suspense } from 'react';

const fetchData = async () => {
  // Simulate API call
  const response = await fetch('api/endpoint');
  return response.json();
};

const MyStreamingComponent = () => {
  return (
    <>
      <header>
        <h1>Streaming Server Rendering</h1>
      </header>
      <Suspense fallback={<div>Loading...</div>}>
        <SlowDataComponent />
      </Suspense>
    </>
  );
};

const SlowDataComponent = async () => {
  const data = await fetchData();
  return <div>{data}</div>;
};

export default MyStreamingComponent;
```

```jsx
// app/javascript/packs/registration.jsx
import MyStreamingComponent from '../components/MyStreamingComponent';

ReactOnRails.register({ MyStreamingComponent });
```

3. **Add The Component To Your Rails View**

```erb
<!-- app/views/example/show.html.erb -->

<%=
  stream_react_component(
    'MyStreamingComponent',
    props: { greeting: 'Hello, Streaming World!' },
    prerender: true
  )
%>

<footer>
  <p>Footer content</p>
</footer>
```

4. **Render The View Using The `stream_view_containing_react_components` Helper**

Ensure you have a controller that renders the view containing the React components. The controller must include the `ReactOnRails::Controller`, `ReactOnRailsPro::Stream` and `ActionController::Live` modules.

```ruby
# app/controllers/example_controller.rb

class ExampleController < ApplicationController
  include ActionController::Live
  include ReactOnRails::Controller
  include ReactOnRailsPro::Stream

  def show
    stream_view_containing_react_components(template: 'example/show')
  end
end
```

5. **Test Your Application**

You can test your application by running `rails server` and navigating to the appropriate route.

6. **What Happens During Streaming**

When a user visits the page, they'll experience the following sequence:

1. The initial HTML shell is sent immediately, including:
   - The page layout
   - Any static content (like the `<h1>` and footer)
   - Placeholder content for the React component (typically a loading state)

2. As the React component processes and suspense boundaries resolve:
   - HTML chunks are streamed to the browser progressively
   - Each chunk updates a specific part of the page
   - The browser renders these updates without a full page reload

For example, with our `MyStreamingComponent`, the sequence might be:

1. The initial HTML includes the header, footer, and loading state.

```html
<header>
  <h1>Streaming Server Rendering</h1>
</header>
<template id="s0">
  <div>Loading...</div>
</template>
<footer>
  <p>Footer content</p>
</footer>
```

2. As the component resolves, HTML chunks are streamed to the browser:

```html
<template hidden id="b0">
  <div>[Fetched data]</div>
</template>

<script>
  // This implementation is slightly simplified
  document.getElementById('s0').replaceChildren(document.getElementById('b0'));
</script>
```

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

This is a significant advantage over `react-helmet`, which requires `renderToString` and is incompatible with streaming. For details, see [React 19 Native Metadata](react-19-native-metadata.md).

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

### Script Loading Strategy for Streaming

**IMPORTANT**: When using streaming server rendering, you should NOT use `defer: true` for your JavaScript pack tags. Here's why:

#### Understanding the Problem with Defer

Deferred scripts (`defer: true`) only execute after the entire HTML document has finished parsing and streaming. This defeats the key benefit of React 18's Selective Hydration feature, which allows streamed components to hydrate as soon as they arrive—even while other parts of the page are still streaming.

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

#### Recommended Approaches

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
<!-- ✅ RECOMMENDED: Use async with immediate_hydration for optimal performance -->
<%= javascript_pack_tag('client-bundle', 'data-turbo-track': 'reload', async: true) %>
```

Note: `async: true` with the `immediate_hydration` feature allows components to hydrate during page load, improving TTI even without streaming. See the Immediate Hydration section below for configuration details.

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

See the [Redux Store API documentation](../api-reference/redux-store-api.md) for more details on Redux shared stores.

#### Why Async is Better Than No Defer

With Shakapacker ≥ 8.2.0, using `async: true` provides the best performance:

- **No defer/async**: Scripts block HTML parsing and streaming
- **defer: true**: Scripts wait for complete page load (defeats Selective Hydration)
- **async: true**: Scripts load in parallel and execute ASAP, enabling:
  - Selective Hydration to work immediately
  - Components to become interactive as they stream in
  - Optimal Time to Interactive (TTI)

#### Migration Timeline

1. **Before Shakapacker 8.2.0**: Use `defer: false` for streaming pages
2. **Shakapacker ≥ 8.2.0**: Migrate to `async: true` for all pages (streaming and non-streaming)
3. **Enable `immediate_hydration`**: Configure for optimal Time to Interactive (see section below)

#### Configuring Immediate Hydration

React on Rails Pro supports the `immediate_hydration` feature, which allows components to hydrate during the page loading state (before DOMContentLoaded). This works optimally with `async: true` scripts:

```ruby
# config/initializers/react_on_rails.rb
ReactOnRails.configure do |config|
  config.immediate_hydration = true # Enable early hydration

  # Optional: Configure pack loading strategy globally
  config.generated_component_packs_loading_strategy = :async
end
```

**Benefits of `immediate_hydration` with `async: true`:**

- Components become interactive as soon as their JavaScript loads
- No need to wait for DOMContentLoaded or full page load
- Optimal Time to Interactive (TTI) for both streaming and non-streaming pages
- Works seamlessly with React 18's Selective Hydration

**Note:** The `immediate_hydration` feature requires a React on Rails Pro license.

**Component-Level Control:**

You can also enable immediate hydration on a per-component basis:

```erb
<%= react_component('MyComponent', props: {}, immediate_hydration: true) %>
```

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
