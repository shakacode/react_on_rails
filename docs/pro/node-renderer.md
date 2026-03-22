# Node Renderer

The React on Rails Pro Node Renderer replaces ExecJS with a dedicated Node.js server for server-side rendering. It eliminates the limitations of embedded JavaScript execution and provides significant performance improvements for production applications.

## Why Use the Node Renderer?

ExecJS embeds a JavaScript runtime (mini_racer/V8) inside the Ruby process. This works for small apps but creates problems at scale:

- **Memory pressure** — V8 contexts consume memory inside each Ruby process, competing with Rails for resources
- **No Node tooling** — You cannot use standard Node.js profiling, debugging, or memory leak detection tools with ExecJS
- **Process crashes** — JavaScript memory leaks can crash your Ruby server
- **Limited concurrency** — ExecJS renders synchronously within the Ruby request cycle

The Pro Node Renderer solves all of these by running a standalone Node.js server that handles rendering requests from Rails over HTTP.

## Performance Benefits

| Metric               | ExecJS                      | Node Renderer            |
| -------------------- | --------------------------- | ------------------------ |
| SSR throughput       | Baseline                    | 10-100x faster           |
| Memory isolation     | Shared with Ruby            | Separate process         |
| Worker concurrency   | Single-threaded per request | Configurable worker pool |
| Profiling            | Not available               | Full Node.js tooling     |
| Memory leak recovery | Crashes Ruby                | Rolling worker restarts  |

At [Popmenu](https://www.shakacode.com/recent-work/popmenu/) (a ShakaCode client), switching to the Node Renderer contributed to a 73% decrease in average response times and 20-25% lower Heroku costs across tens of millions of daily SSR requests.

## How It Works

1. Rails sends a rendering request (component name, props, and JavaScript bundle reference) to the Node Renderer over HTTP
2. The Node Renderer evaluates the server bundle in a Node.js worker
3. The rendered HTML is returned to Rails and inserted into the view
4. Workers are pooled and can be automatically restarted to mitigate memory leaks

## Key Features

- **Worker pool** — Configurable number of workers (defaults to CPU count minus 1)
- **Rolling restarts** — Automatic worker recycling to prevent memory leak buildup
- **Bundle caching** — Server bundles are cached on the Node side for fast re-renders
- **Shared secret authentication** — Secure communication between Rails and Node
- **Prerender caching** — Combined with [prerender caching](../oss/building-features/caching.md#level-1-prerender-caching), rendering results are cached across requests

## Getting Started

### Quick Setup (Generator)

The fastest way to set up the Node Renderer is with the Pro generator:

```bash
bundle exec rails generate react_on_rails:pro
```

This creates the Node Renderer entry point, configures webpack, and adds the renderer to `Procfile.dev`.

### Manual Setup

For fine-grained control, see the [Node Renderer installation section](./installation.md#node-renderer-installation) in the installation guide.

### Configuration

Configure Rails to use the Node Renderer:

```ruby
# config/initializers/react_on_rails_pro.rb
ReactOnRailsPro.configure do |config|
  config.server_renderer = "NodeRenderer"
  config.renderer_url = ENV["REACT_RENDERER_URL"] || "http://localhost:3800"
  config.renderer_password = ENV.fetch("RENDERER_PASSWORD", "devPassword")
end
```

## Further Reading

- [Node Renderer basics](../oss/building-features/node-renderer/basics.md) — Architecture and core concepts
- [JavaScript configuration](../oss/building-features/node-renderer/js-configuration.md) — Node-side config options
- [Error reporting and tracing](../oss/building-features/node-renderer/error-reporting-and-tracing.md) — Monitoring in production
- [Heroku deployment](../oss/building-features/node-renderer/heroku.md) — Deploy the renderer on Heroku
- [Debugging](../oss/building-features/node-renderer/debugging.md) — Troubleshooting renderer issues
- [Troubleshooting](../oss/building-features/node-renderer/troubleshooting.md) — Common problems and solutions
