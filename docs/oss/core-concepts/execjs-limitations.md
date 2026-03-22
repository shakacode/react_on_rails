# ExecJS Limitations

React on Rails uses [ExecJS](https://github.com/rails/execjs) as the default server-side rendering engine. ExecJS provides a common interface to several JavaScript runtimes (Node.js, mini_racer, etc.) and works well for basic server rendering, but it has important limitations to understand.

## How ExecJS Works

ExecJS evaluates your server bundle in an isolated JavaScript context. It calls your render function synchronously, collects the resulting HTML string, and returns it to Rails. This synchronous model is the root of most limitations — ExecJS cannot wait for asynchronous operations to complete.

By default, ExecJS uses the Node.js runtime. You can also use [mini_racer](https://github.com/rubyjs/mini_racer) (a V8 isolate). Both runtimes share the same synchronous limitations described below. See the [ExecJS readme](https://github.com/rails/execjs/blob/master/README.md) for all available runtimes.

## Timer and Async Limitations

### `setTimeout` and `setInterval`

ExecJS does not support `setTimeout`, `setInterval`, `clearTimeout`, or `clearInterval`. These functions rely on an event loop, which ExecJS does not provide. React on Rails injects stub functions that silently replace these timer APIs. With `trace: true` in your configuration, the stubs log a warning to `console.error` with a stack trace; otherwise, calls are silently dropped.

**What you'll see:** Timer callbacks are never executed. If `trace` is enabled, you'll see messages like:

```text
[React on Rails Rendering] setTimeout is not defined for server rendering.
```

**Why this matters:** Many libraries use timers internally for debouncing, animations, polling, or deferred execution. When these libraries run during server rendering with ExecJS, the timer callbacks are silently dropped, which can cause missing content or unexpected behavior.

**Workarounds:**

```javascript
// Guard timer calls with an environment check
if (typeof window !== 'undefined') {
  setTimeout(() => doSomething(), 100);
}

// Or use useEffect, which only runs on the client
useEffect(() => {
  const timer = setTimeout(() => doSomething(), 100);
  return () => clearTimeout(timer);
}, []);
```

### Promises and Async/Await

ExecJS cannot wait for Promises to resolve. Since the rendering call is synchronous, any data fetching or asynchronous initialization that relies on Promises will not complete before the HTML is returned.

**What fails:**

```javascript
// This component will render before data loads
async function UserProfile({ userId }) {
  const data = await fetch(`/api/users/${userId}`); // Never completes in ExecJS
  return <div>{data.name}</div>;
}
```

**Workaround:** Pass all required data as props from Rails rather than fetching it client-side during rendering:

```ruby
# In your Rails controller
@props = { user: User.find(params[:id]).as_json }
```

```erb
<%= react_component('UserProfile', props: @props, prerender: true) %>
```

### File System Access

ExecJS does not provide `fs`, `path`, or other Node.js built-in modules. Code that reads configuration files, templates, or other resources from the file system will fail.

## The `window` Object

ExecJS does not provide a `window`, `document`, or any DOM API. Server rendering runs in a headless JavaScript context with no browser environment.

**Common error messages:**

```text
ReferenceError: window is not defined
ReferenceError: document is not defined
```

**Workarounds:**

```javascript
// Check before accessing
const isClient = typeof window !== 'undefined';
const screenWidth = isClient ? window.innerWidth : 1200;

// Better: use useEffect for DOM access
useEffect(() => {
  const width = window.innerWidth;
  setWidth(width);
}, []);
```

See [Client vs. Server Rendering](./client-vs-server-rendering.md) for more on handling browser-only code.

## `TextEncoder` / `TextDecoder`

When using `mini_racer`, you may encounter:

```text
ReferenceError: TextEncoder is not defined
```

This is because mini_racer's V8 isolate does not include the `TextEncoder` and `TextDecoder` Web APIs. See [this solution](https://github.com/shakacode/react_on_rails/issues/1457#issuecomment-1165026717) for a polyfill approach.

## Pool Size Constraints

On MRI Ruby, ExecJS uses a single-threaded JavaScript runtime, so `server_renderer_pool_size` must stay at 1 to avoid deadlocks. JRuby users can increase the pool size for concurrent rendering.

```ruby
# config/initializers/react_on_rails.rb
ReactOnRails.configure do |config|
  config.server_renderer_pool_size = 1   # MRI (default)
  # config.server_renderer_pool_size = 5 # JRuby
  config.server_renderer_timeout = 20    # seconds
end
```

## Debugging ExecJS Errors

Enable `trace` mode to get detailed logging for timer calls and other server rendering issues:

```ruby
ReactOnRails.configure do |config|
  config.trace = true
  config.logging_on_server = true
  config.replay_console = true
  config.raise_on_prerender_error = Rails.env.development?
end
```

With these settings, ExecJS errors will:

- Raise exceptions in development so you catch them immediately
- Log server-side rendering output to `Rails.logger.info`
- Replay server-side console messages in the browser console (via `replay_console`)

See the [Configuration Reference](../configuration/README.md) for details on these options.

## Migrating to the Node Renderer

If ExecJS limitations are blocking your application, the [Node Renderer](../building-features/node-renderer/basics.md) (a React on Rails Pro feature) eliminates these constraints by running a dedicated Node.js process for server rendering. The Node renderer supports:

- Full async/await and Promise resolution
- `setTimeout` and `setInterval` (requires setting `RENDERER_STUB_TIMERS=false`; timers are stubbed by default)
- Streaming SSR with `renderToPipeableStream`
- React Server Components
- Node.js built-in modules (requires setting `RENDERER_SUPPORT_MODULES=true`)
- Multi-worker concurrency

The Node renderer typically delivers significantly faster SSR compared to ExecJS, with real-world results like Popmenu's [73% reduction in response times](https://www.shakacode.com/recent-work/popmenu/). See [OSS vs Pro](../getting-started/oss-vs-pro.md) for a full feature comparison.
