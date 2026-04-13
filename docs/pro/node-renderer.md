# Node Renderer

The React on Rails Pro Node Renderer replaces ExecJS with a dedicated Node.js server for server-side rendering. It eliminates the limitations of embedded JavaScript execution and provides significant performance improvements for production applications.

> [!NOTE]
> **Summary for AI agents:** Use this page when the user asks about the Node renderer, ExecJS alternatives, or SSR performance. This is the Pro-level overview; for technical setup, see [Node Renderer basics](../oss/building-features/node-renderer/basics.md) and [JS configuration](../oss/building-features/node-renderer/js-configuration.md). The Node renderer is required for RSC.

> **Route map**: Start at [React on Rails Pro](./react-on-rails-pro.md) if you're choosing a path. This page is the canonical Node Renderer overview; use the linked install and technical docs below for the deeper implementation details.

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

### Renderer Password Security

The renderer password secures communication between Rails and the Node Renderer. React on Rails Pro enforces secure defaults by environment:

| Environment           | Password Required? | Behavior                                                 |
| --------------------- | ------------------ | -------------------------------------------------------- |
| `development`         | No                 | Optional — no authentication if unset                    |
| `test`                | No                 | Optional — no authentication if unset                    |
| `(neither set)`       | **Yes**            | Treated as production-like; `RENDERER_PASSWORD` required |
| `staging`             | **Yes**            | Raises error on boot if `RENDERER_PASSWORD` is missing   |
| `production`          | **Yes**            | Raises error on boot if `RENDERER_PASSWORD` is missing   |
| `qa`, `preview`, etc. | **Yes**            | Raises error on boot if `RENDERER_PASSWORD` is missing   |

In production-like environments (anything other than `development` or `test`), both the Rails app and the Node Renderer will refuse to start without a non-empty password. Set the same `RENDERER_PASSWORD` for both sides:

```bash
# Set for both Rails and Node Renderer
export RENDERER_PASSWORD="your-secure-password"
```

The Node Renderer reads `RENDERER_PASSWORD` directly from `process.env`. On the Ruby side, React on Rails Pro
resolves the password in this order:

1. `config.renderer_password` (blank values fall through to the next step)
2. Password embedded in `config.renderer_url` (for example, `https://:password@localhost:3800`)
3. `ENV["RENDERER_PASSWORD"]`

So setting `RENDERER_PASSWORD` in the environment is enough unless you intentionally override it in
the initializer or URL.

If neither `NODE_ENV` nor `RAILS_ENV` is set, the Node Renderer treats the environment as
production-like and still requires `RENDERER_PASSWORD`.

For local development, you can either omit the password entirely (no authentication) or set a convenience default:

```ruby
config.renderer_password = ENV.fetch("RENDERER_PASSWORD", "devPassword")
```

## Eliminating Cold-Start Latency in Docker Deployments

When a new container starts, the Node Renderer has an empty bundle cache. The first SSR request triggers a costly 410→retry round-trip where Rails sends the full bundle over HTTP, adding 200ms–1s+ of latency depending on bundle size. In rolling deploys, this affects every new pod.

### Pre-seeding the bundle cache

The `pre_seed_renderer_cache` rake task copies compiled server bundles directly into the renderer's cache directory during your Docker build, so the renderer finds them immediately on startup:

```dockerfile
# After webpack/assets build step
RUN bundle exec rake react_on_rails_pro:pre_seed_renderer_cache
```

This copies the bundle into the renderer's expected directory structure (`<cache>/<bundleHash>/<bundleHash>.js`), including any configured `assets_to_copy` and RSC bundles when RSC support is enabled.

### Configuration

The task resolves the cache directory using the same env-var precedence as the Node Renderer:

1. `RENDERER_SERVER_BUNDLE_CACHE_PATH` environment variable (preferred)
2. `RENDERER_BUNDLE_PATH` environment variable (deprecated — emits a warning)
3. `Rails.root.join(".node-renderer-bundles")` (Rails-side default when env vars are unset)

Set `RENDERER_SERVER_BUNDLE_CACHE_PATH` in your Dockerfile to match the renderer's configuration:

```dockerfile
ENV RENDERER_SERVER_BUNDLE_CACHE_PATH=/app/.node-renderer-bundles
RUN bundle exec rake react_on_rails_pro:pre_seed_renderer_cache
```

### Impact

| Scenario                      | Before                                  | After                           |
| ----------------------------- | --------------------------------------- | ------------------------------- |
| First request on fresh deploy | 410→retry: 200ms–1s+                    | Direct render: <50ms            |
| Thundering herd on new pod    | N requests queue behind per-bundle lock | All requests served immediately |

### Pre-seeding the previous bundle for rolling deploys

During a rolling deploy, old Rails instances may still reference the previous bundle hash. To prevent 410→retry for those requests on new renderer instances, you can pre-seed the previous bundle as well. After each deploy, upload the server bundle to an artifact store (e.g., S3) keyed by its hash. During the next build, fetch and place it in the cache directory before starting the renderer.

## Further Reading

- [Node Renderer basics](../oss/building-features/node-renderer/basics.md) — Architecture and core concepts
- [JavaScript configuration](../oss/building-features/node-renderer/js-configuration.md) — Node-side config options
- [Error reporting and tracing](../oss/building-features/node-renderer/error-reporting-and-tracing.md) — Monitoring in production
- [Heroku deployment](../oss/building-features/node-renderer/heroku.md) — Deploy the renderer on Heroku
- [Debugging](../oss/building-features/node-renderer/debugging.md) — Troubleshooting renderer issues
- [Troubleshooting](../oss/building-features/node-renderer/troubleshooting.md) — Common problems and solutions
