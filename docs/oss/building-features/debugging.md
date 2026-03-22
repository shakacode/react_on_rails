# Debugging React on Rails

This guide covers common debugging workflows for React on Rails applications, focusing on server-side rendering issues, hydration mismatches, and tools for diagnosing problems.

## Configuration for Debugging

React on Rails provides several configuration options that help with debugging. Enable them in development:

```ruby
# config/initializers/react_on_rails.rb
ReactOnRails.configure do |config|
  # Detailed logging for server rendering, including stack traces for
  # setTimeout/setInterval calls
  config.trace = Rails.env.development?

  # Log server rendering output to Rails.logger.info
  config.logging_on_server = true

  # Replay server-side console.log messages in the browser console
  config.replay_console = true

  # Raise exceptions when server rendering fails (instead of rendering
  # an error message in the HTML)
  config.raise_on_prerender_error = Rails.env.development?
end
```

See the [Configuration Reference](../configuration/README.md) for full documentation on these options.

## Debugging Server-Side Rendering

### Reading Server Rendering Output

When `logging_on_server` is `true` (the default), server rendering messages appear in your Rails log. Check `log/development.log` or your terminal output for lines related to React on Rails rendering.

When `replay_console` is `true` (the default), any `console.log`, `console.warn`, or `console.error` calls from your server-rendered JavaScript will replay in the browser's developer console. This is one of the most useful tools for understanding what your components are doing during server rendering.

### Common SSR Errors

**`ReferenceError: window is not defined`**

Your component accesses `window`, `document`, or another browser API during server rendering. Guard with an environment check or move the code into `useEffect`:

```javascript
// Guard approach
const isClient = typeof window !== 'undefined';

// useEffect approach (preferred)
useEffect(() => {
  // Browser-only code here
}, []);
```

**`TypeError: Cannot read properties of undefined`**

Often caused by accessing props that are `nil` in Ruby but become `undefined` in JavaScript. Check your prop serialization:

```ruby
# Ensure props are present
@props = {
  user: @user&.as_json || {},
  items: @items || []
}
```

**`setTimeout is not defined` or async errors**

These occur when using ExecJS, which does not support timers or async operations. See the [ExecJS Limitations](../core-concepts/execjs-limitations.md) guide for workarounds.

### Using `trace` Mode

When `config.trace` is enabled, React on Rails logs additional details about the server rendering process, including stack traces when `setTimeout` or `setInterval` are called during ExecJS rendering. This helps identify which library or component is making unsupported calls.

## Debugging Hydration Mismatches

Hydration mismatches occur when the server-rendered HTML differs from what React generates on the client. React will warn in the browser console:

```text
Warning: Text content did not match. Server: "March 21" Client: "March 22"
```

### Common Causes

**Time-dependent rendering:** Server and client render at different times, producing different date/time strings.

```javascript
// Problem: different output on server vs client
const now = new Date().toLocaleDateString();

// Fix: pass the timestamp as a prop from Rails
// In controller:
@props = { timestamp: Time.current.iso8601 }
```

**Random values:** `Math.random()` or UUID generation produces different values between renders.

```javascript
// Problem: different ID on server vs client
const id = `item-${Math.random()}`;

// Fix: use a deterministic ID
const id = `item-${props.itemId}`;
```

**Browser-only code affecting initial render:** Code that checks `window` dimensions or feature detection may produce different initial output.

```javascript
// Problem: server renders one thing, client another
const isMobile = typeof window !== 'undefined' && window.innerWidth < 768;

// Fix: defer to useEffect so the initial render matches the server
const [isMobile, setIsMobile] = useState(false);
useEffect(() => {
  setIsMobile(window.innerWidth < 768);
}, []);
```

### Inspecting Server-Rendered HTML

To see exactly what the server rendered, view the page source (not the DOM inspector, which shows the hydrated DOM). In your browser:

1. Navigate to the page
2. Right-click and select **View Page Source** (or use `Ctrl+U` / `Cmd+U`)
3. Search for your component's container div (e.g., `id="MyComponent-react-component-<uuid>"` when `random_dom_id` is enabled, which is the default)

The HTML inside that div is what the server produced. Compare it with what React expects to render on the client.

You can also add `console.log` statements in your component to see the props and state during both renders:

```javascript
function MyComponent(props) {
  console.log('Rendering MyComponent with props:', props);
  // ...
}
```

With `replay_console` enabled, the server-side log will appear in the browser console alongside the client-side log, making it easy to compare.

## Where to Find Logs

### Rails Server Logs

Server rendering output, including errors and console replays, appears in:

- **Terminal:** where you run `rails server` or `bin/dev`
- **Log file:** `log/development.log` (or `log/test.log` for test environment)

### Webpack/Rspack Build Logs

Build errors and warnings appear in:

- **Terminal:** where webpack-dev-server or `bin/dev` runs
- **Browser console:** webpack overlay may show compilation errors

To run diagnostics on your React on Rails setup (checks configuration, file existence, and common issues):

```bash
bundle exec rake react_on_rails:doctor
```

### Browser Console

The browser developer console shows:

- Replayed server-side `console.log` messages (when `replay_console` is enabled)
- React hydration warnings
- Client-side JavaScript errors
- Component registration status

### Checking Component Registration

To verify that your components are registered correctly:

```javascript
// In the browser console
console.log(ReactOnRails.registeredComponents());
```

This returns a map of all components that have been registered with `ReactOnRails.register()`. If your component is missing, check that the registration file is included in your webpack entry point.

## Debugging Webpack Configuration

If components aren't loading or you suspect bundling issues:

1. Check that your webpack entry points include the registration files
2. Verify the manifest file exists at the expected path (check `public_output_path` in `config/shakapacker.yml` — defaults to `public/packs/`)
3. Confirm the server bundle is generated in your `server_bundle_output_path` (defaults to `ssr-generated/`):

```bash
# List the server bundle output directory (filename set via config.server_bundle_js_file)
ls ssr-generated/

# Check that the client manifest exists and contains your client bundles
cat public/packs/manifest.json | grep "application"
```

## Pro Node Renderer Debugging

If you're using the React on Rails Pro Node Renderer, the renderer process has its own logs. The log level is controlled by the `RENDERER_LOG_LEVEL` environment variable. See the [Node Renderer Basics](./node-renderer/basics.md) for configuration details.

## Additional Resources

- [Troubleshooting Guide](../deployment/troubleshooting.md) — common installation, build, and runtime issues
- [ExecJS Limitations](../core-concepts/execjs-limitations.md) — timer, async, and environment constraints
- [Client vs. Server Rendering](../core-concepts/client-vs-server-rendering.md) — when and how to use SSR
- [Configuration Reference](../configuration/README.md) — all configuration options
- [Testing Configuration](./testing-configuration.md) — setting up test environments
