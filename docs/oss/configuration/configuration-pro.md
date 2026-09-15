# React on Rails Pro Configuration

> **Pro Feature** — Available with [React on Rails Pro](../../pro/react-on-rails-pro.md).
> Free or very low cost for startups and small companies. [Upgrade or licensing details →](../../pro/upgrading-to-pro.md#try-pro-risk-free)

For general React on Rails configuration options, see [Configuration](README.md).

`config/initializers/react_on_rails_pro.rb`

1. You don't need to create an initializer if you are satisfied with the defaults as described below.
1. Values beginning with `renderer` pertain only to using an external rendering server. You will need to ensure these values are consistent with your configuration for the external rendering server, as given in [JS configuration](../building-features/node-renderer/js-configuration.md)
1. `config.prerender_caching` works for standard ExecJS server rendering and using an external rendering server.

## Example of Configuration

Also see [spec/dummy/config/initializers/react_on_rails_pro.rb](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails_pro/spec/dummy/config/initializers/react_on_rails_pro.rb) for how the testing app is setup.

The below example is a typical production setup, using the separate `NodeRenderer`, where development takes the defaults when the ENV values are not specified.

```ruby
ReactOnRailsPro.configure do |config|
  # Paid production license JWT. Explicit nonblank configuration takes precedence over
  # REACT_ON_RAILS_PRO_LICENSE; blank values fall back to that environment variable.
  # A standalone Node renderer must receive the same token through its own `licenseToken`
  # configuration or environment.
  config.license_token = Rails.application.credentials.dig(:react_on_rails_pro, :license_token)

  # If true, then capture timing of React on Rails Pro calls including server rendering and
  # component rendering.
  # Default for `tracing` is false.
  config.tracing = true

  # Array of globs to find any files for which changes should bust the fragment cache for
  # cached_react_component and cached_react_component_hash. This should include any files used to
  # generate the JSON props, webpack and/or webpacker configuration files, and npm package lockfiles.
  # Default for `dependency_globs` is an empty array
  config.dependency_globs = [ File.join(Rails.root, "app", "views", "**", "*.jbuilder") ]

  # Array of globs to exclude from config.dependency_globs for ReactOnRailsPro cache key hashing
  # Default for `excluded_dependency_globs` is an empty array
  config.excluded_dependency_globs = [ File.join(Rails.root, "app", "views", "**", "dont_hash_this.jbuilder") ]

  # Remote bundle caching saves deployment time by caching bundles.
  # See /docs/oss/building-features/bundle-caching.md for usage and examples.
  config.remote_bundle_cache_adapter = nil

  # ALL OPTIONS BELOW ONLY APPLY IF SERVER RENDERING

  # If true, then cache the evaluation of JS for prerendering using the standard Rails cache.
  # Applies to all rendering engines.
  # Default for `prerender_caching` is false.
  config.prerender_caching = true

  # Retry request in case of time out on the node-renderer side
  # 5 - default, if not specified
  # 0 - no retry
  config.renderer_request_retry_limit = 5

  # NodeRenderer is for a renderer that is stateless. It does not need restarting when the JS bundles
  # are updated. It is the only custom renderer currently supported. Leave blank to use the standard
  # ExecJS rendering. Other option is NodeRenderer
  # Default for `server_renderer` is "ExecJS"
  config.server_renderer = "NodeRenderer"

  # React on Rails Node Renderer now support render functions returning promises! To enable this optional functionality,
  # toggle the following option.
  # Default is false.
  config.rendering_returns_promises = false

  # If you're using the NodeRenderer, a value of true allows errors to be thrown from the bundle
  # code for SSR so that an error tracking system on the NodeRender can use the exceptions.
  # If you are using ExecJS as your rendering method, set this to false.
  # Default is true.
  config.throw_js_errors = true

  # You may provide a password and/or a port that will be sent to renderer for simple authentication.
  # `https://:<password>@url:<port>`. For example: https://:YOUR_SECURE_PASSWORD@renderer:3800. Don't forget
  # the leading `:` before the password. Your password must also not contain certain characters that
  # would break calling URI(config.renderer_url). This includes: `@`, `#`, '/'.
  # **Note:** Don't forget to set up **SSL** connection (https) otherwise password will useless
  # since it will be easy to intercept it.
  # If you provide an ENV value (maybe only for production) and there is no value, then you get the default.
  # Default for `renderer_url` is "http://localhost:3800".
  config.renderer_url = ENV["REACT_RENDERER_URL"]

  # Force HTTP/2 prior knowledge (h2c) for cleartext renderer URLs. Set false
  # only when the Node Renderer also sets
  # `fastifyServerOptions: { http2: false }`. See "Renderer HTTP Transport"
  # below for HTTPS, async-props, proxy, concurrency, and rollout constraints.
  # Default for `renderer_http_force_http2` is true.
  # config.renderer_http_force_http2 = false

  # If you don't want to worry about special characters in your password within the url, use this config value
  # Default for `renderer_password` is nil
  # config.renderer_password = ENV["RENDERER_PASSWORD"]

  # Set the `ssr_timeout` configuration so the Rails server will not wait more than this many seconds
  # for a renderer socket read once issued. With the async-http renderer client, this is applied as
  # the per-read socket timeout on the renderer connection. Increase this value for long-running
  # streaming SSR responses with legitimate gaps between chunks.
  config.ssr_timeout = 5

  # Controls the buffer size for concurrent component streaming. When multiple
  # streamed React components render concurrently, each writes chunks into a
  # buffer of this size before flushing to the HTTP response. Increase for
  # pages with many concurrent streamed components; decrease to lower memory
  # usage per request. Must be a positive integer.
  # Default: 64
  # config.concurrent_component_streaming_buffer_size = 64

  # Controls error handling for streaming SSR errors that occur after the
  # initial shell HTML has been flushed to the client. When false (default),
  # errors in async/Suspense boundaries during streamed RSC rendering are
  # swallowed — the client sees the shell but the failing boundary never
  # resolves. When true, those post-shell errors raise as exceptions on the
  # Rails side, which typically aborts the stream. Set to true in
  # development/test to surface all rendering errors; keep false in production
  # where a partial page is usually better than no page.
  # Default: false
  # config.raise_non_shell_server_rendering_errors = false

  # If false, then crash if no backup rendering when the remote renderer is not available
  # Can be useful to set to false in development or testing to make sure that the remote renderer
  # works and any non-availability of the remote renderer does not just do ExecJS.
  # Suggest setting this to false if the SSR JS code cannot run in ExecJS
  # Default for `renderer_use_fallback_exec_js` is true.
  config.renderer_use_fallback_exec_js = false

  # Maximum number of concurrent async-http connections per client to the Node renderer.
  # HTTP/2 may multiplex request streams, while each HTTP/1.1 connection handles one
  # request at a time. With a long-lived Fiber.scheduler, HTTP/1.1 therefore makes
  # this setting a hard shared-client request-concurrency cap. Standard Puma uses
  # ephemeral clients for streaming renders and persistent per-thread clients for
  # non-streaming renders, so it has no process-wide shared-client cap.
  # See "Renderer Performance Tuning for Streamed RSC" below.
  # Default for `renderer_http_pool_size` is 10
  config.renderer_http_pool_size = 10

  # TCP connect timeout in seconds. After the socket connects, request processing and streaming
  # are bounded by `ssr_timeout`.
  # Default for `renderer_http_pool_timeout` is 5
  config.renderer_http_pool_timeout = 5

  # warn_timeout  - Displays a warning message if a request takes longer than the given time in seconds.
  # Default is 0.25
  config.renderer_http_pool_warn_timeout = 0.25 # seconds

  # Snippet of JavaScript to be run right at the beginning of the server rendering process. The code
  # to be executed must either be self contained or reference some globally exposed module.
  # For example, suppose that we had to call `SomeLibrary.clearCache()`between every call to server
  # renderer to ensure no leakage of state between calls. Note, SomeLibrary needs to be globally
  # exposed in the server rendering webpack bundle. This code is visible in the tracing of the calls
  # to do server rendering. Default is nil.
  config.ssr_pre_hook_js = "SomeLibrary.clearCache();"

  # When using the Node Renderer, you may require some extra assets in addition to the bundle.
  # The assets_to_copy option allows the Node Renderer to have assets copied at the end of
  # the assets:precompile task or directly by the
  # react_on_rails_pro:copy_assets_to_remote_vm_renderer task.
  # These assets are also transferred any time a new bundle is sent from Rails to the renderer.
  # The value should be a file_path or an Array of file_paths. The files should have extensions
  # to resolve the content types, such as "application/json".
  config.assets_to_copy = [
     Rails.root.join("public", "webpack", Rails.env, "loadable-stats.json"),
     Rails.root.join("public", "webpack", Rails.env, "manifest.json")
  ]

  ################################################################################
  # REACT SERVER COMPONENTS (RSC) CONFIGURATION
  ################################################################################

  # Enable React Server Components support
  # When enabled, React on Rails Pro will support RSC rendering and streaming
  # Default is false
  config.enable_rsc_support = true

  # Optional authorization callback for the mounted RSC payload endpoint.
  # It receives the Rails controller and the requested component name before
  # props are parsed or rendering begins. A false or nil result returns 403.
  # Default is nil, which preserves the endpoint's existing allow-all behavior.
  allowed_rsc_components = %w[AccountPage DashboardPage].freeze
  config.rsc_payload_authorizer = lambda do |controller, component_name|
    controller.session[:user_id].present? && allowed_rsc_components.include?(component_name)
  end

  # Path to the RSC bundle file (relative to webpack output directory or absolute path)
  # The RSC bundle contains only server components and references to client components.
  # It's generated using the RSC Webpack Loader which transforms client components into
  # references. This bundle is specifically used for generating RSC payloads and is
  # configured with the 'react-server' condition.
  # Default is "rsc-bundle.js"
  config.rsc_bundle_js_file = "rsc-bundle.js"

  # Path to the React client manifest file (typically in your webpack output directory)
  # This manifest contains mappings for client components that need hydration.
  # It's automatically generated by the React Server Components Webpack plugin and is
  # required for client-side hydration of components.
  # Only set this if you've configured the plugin to use a different filename.
  # Default is "react-client-manifest.json"
  config.react_client_manifest_file = "react-client-manifest.json"

  # Path to the React server-client manifest file (typically in your webpack output directory)
  # This manifest is used during server-side rendering with RSC to properly resolve
  # references between server and client components.
  # It's automatically generated by the React Server Components Webpack plugin.
  # Only set this if you've configured the plugin to use a different filename.
  # Default is "react-server-client-manifest.json"
  config.react_server_client_manifest_file = "react-server-client-manifest.json"

  # These RSC configuration files are crucial when implementing React Server Components
  # with streaming, which offers benefits like:
  # - Reduced JavaScript bundle sizes
  # - Faster page loading
  # - Selective hydration of client components
  # - Progressive rendering with Suspense boundaries

  # URL path prefix for RSC payload generation routes. This is the base path
  # where the mounted RSC payload endpoint serves Flight payloads.
  # See: https://reactonrails.com/docs/pro/react-server-components/how-react-server-components-work
  # Default: "rsc_payload/"
  # config.rsc_payload_generation_url_path = "rsc_payload/"

  ################################################################################
  # ROLLING DEPLOY CONFIGURATION
  ################################################################################

  # Adapter for seeding previously-deployed bundle hashes into the Node Renderer
  # cache during rolling deploys. The built-in adapter is
  # ReactOnRailsPro::RollingDeployAdapters::Http; custom adapters must implement
  # the rolling-deploy protocol (previous_bundle_hashes, fetch, upload).
  # See: https://reactonrails.com/docs/pro/rolling-deploy-adapters
  # Default: nil
  # config.rolling_deploy_adapter = nil

  # Bearer token for the HTTP rolling-deploy adapter (minimum 32 bytes).
  # Required when using the built-in Http adapter.
  # Default: nil
  # config.rolling_deploy_token = nil

  # URL(s) to seed bundles from during a rolling deploy. Accepts a string,
  # comma-separated string, or Array of URLs.
  # Default: nil
  # config.rolling_deploy_previous_urls = nil

  # Auto-mount path for the rolling-deploy bundles controller. Set to nil or
  # blank to opt out of auto-mounting and keep a manual mount.
  # Default: "/react_on_rails_pro/rolling_deploy"
  # config.rolling_deploy_mount_path = "/react_on_rails_pro/rolling_deploy"

  ################################################################################
  # PROFILING
  ################################################################################

  # Enable server-side rendering JavaScript code profiling. When true, the Pro
  # gem generates V8 CPU profiles during server rendering that can be analyzed
  # with `rake react_on_rails_pro:process_v8_logs`.
  # **ExecJS only** — this setting has no effect when using the Pro Node
  # Renderer (`server_renderer = "NodeRenderer"`). It reconfigures the ExecJS
  # runtime to use `node --prof` or `d8 --prof`.
  # See: https://reactonrails.com/docs/pro/profiling-server-side-rendering-code
  # Default: false
  # config.profile_server_rendering_js_code = false

  ################################################################################
  # CACHE TAG INDEX
  ################################################################################

  # TTL for tag-based cache index entries (in seconds or ActiveSupport::Duration).
  # Controls how long the tag->cache-key index entries live. After expiry, a
  # revalidateTag call cannot find the entry — the cached fragment still lives
  # until its own expires_in, but it won't be invalidated by tag.
  # See: https://reactonrails.com/docs/building-features/caching
  # Default: 604800 (7 days)
  # config.cache_tag_index_expires_in = 604800

  # Maximum number of cache-entry keys tracked per tag in the index. The oldest
  # keys are dropped (with a warning) beyond this limit.
  # Default: 5000
  # config.cache_tag_index_max_keys = 5000
end
```

## Renderer HTTP Transport

The default renderer transport is cleartext HTTP/2 (h2c). To select HTTP/1.1, pair Node's
`fastifyServerOptions: { http2: false }` with Rails' `config.renderer_http_force_http2 = false`.
`renderer_http_force_http2` applies only to cleartext `http://` URLs; HTTPS selects its protocol through ALPN. With a
long-lived `Fiber.scheduler`, HTTP/1.1 also makes `renderer_http_pool_size` a hard cap on concurrent renderer requests
sharing the client. See
[Node Renderer health checks](../building-features/node-renderer/health-checks.md#choosing-h2c-or-http11) for the
canonical async-props tradeoff, paired configuration, security requirements, proxy settings, probes, and rollout order.

## Renderer Performance Tuning for Streamed RSC

The dominant contributors to a streamed route's `responseEnd` tail are Node renderer round-trip overhead, cold or under-warmed renderer workers, and per-request connection setup between Rails and the renderer. Three levers address these (see [issue #4240](https://github.com/shakacode/react_on_rails/issues/4240)). Measure changes with before/after page-load timing for the streamed route, `Server-Timing` for the early Rails/renderer phases that are known before the first stream write, the inline RSC stream performance marks described in the [Streaming SSR guide](../../pro/streaming-ssr.md), and renderer logs or tracing for cold-worker behavior. Inline marks remain the source for late payload, flush, hydration, and stream-drain timing because `ActionController::Live` commits headers on the first stream write.

### 1. Warm up renderer workers

Each worker compiles its bundle on its **first** render request, so the first measured render after a deploy is cold. Pre-warm every worker before serving real traffic so cold-start cost does not land on a user (or skew a benchmark):

- Send a warm-up render (or hit `/ready` after a warm-up render) to each replica during deploy.
- With `workersCount > 1`, a single warm-up render is not enough. Route warm-up traffic so it reaches **every** worker under your actual load-balancing policy; sticky or hash-based routing may require replica-local hooks or an explicit fan-out endpoint. **Do not gate all traffic on `/ready` without a separate warm-up path** — if no render requests reach the renderer, `/ready` never flips to 200 (deadlock).

Full warm-up patterns (Kubernetes probes, `postStart` hooks, the `/ready` cold-start contract) are in [Node renderer health checks → Gating traffic on `/ready`](../building-features/node-renderer/health-checks.md#gating-traffic-on-ready).

### 2. Size the worker pool and the connection pool together

Two independent limits gate renderer throughput:

| Setting                                                                                             | Where    | Default  | Governs                                                           |
| --------------------------------------------------------------------------------------------------- | -------- | -------- | ----------------------------------------------------------------- |
| [`workersCount`](../building-features/node-renderer/js-configuration.md) / `RENDERER_WORKERS_COUNT` | Renderer | CPUs − 1 | How many renders the renderer can execute concurrently.           |
| `renderer_http_pool_size`                                                                           | Rails    | 10       | Max concurrent async-http connections per client to the renderer. |

Guidance:

- With Falcon or another long-lived scheduler, size `renderer_http_pool_size` at or above peak concurrent renderer requests per scheduler, then confirm that `workersCount` can sustain that load. Streamed renders sharing that scheduler use the same async-http client. HTTP/2 can multiplex request streams, while each HTTP/1.1 connection handles one request at a time and makes this pool size a hard shared-client concurrency cap. Requests beyond the cap wait for a connection without a pool-acquisition timeout; `ssr_timeout` starts only after a socket is acquired.
- Under standard Puma streaming, `Sync {}` creates a request-scoped client, so `renderer_http_pool_size` only bounds concurrent async-http connections inside one streamed response. Use a value near the number of renderer calls one response can overlap; scale `workersCount` and renderer replicas for cross-request concurrency.
- Account for your Rails concurrency: with many Puma threads/workers all streaming, a renderer with only one or two workers becomes the bottleneck. Scale `workersCount` (and renderer replicas) to your real concurrent streamed-render load.
- Tune `ssr_timeout` for legitimate long gaps between streamed chunks — it applies as a per-read socket timeout, so it fires when a single read from the renderer blocks for `ssr_timeout` seconds. It is not a total response-duration cap; avoid masking renderer hangs with an unnecessarily high value.

### 3. Rails ↔ renderer keep-alive (persistent on Falcon/async scheduler; per-request on standard Puma)

Connection reuse is automatic when the renderer request runs under a long-lived `Fiber.scheduler`, such as Falcon or Puma configured with an async scheduler. In that setup, the async-http client is stored on the scheduler and reused across streaming requests, so HTTP/2 connections stay alive and renders multiplex over them instead of paying TCP handshake and H2 connection setup per request ([issue #3283](https://github.com/shakacode/react_on_rails/issues/3283)). No React on Rails configuration is required to enable this.

Under standard Puma, the streaming helper's `Sync {}` block creates a per-request scheduler. The async-http client is cleaned up when that streaming response ends, so connection reuse does not persist across consecutive Rails requests. The benefit is still meaningful inside a single streamed response: renderer calls in that response can share the same client lifecycle and `renderer_http_pool_size` still bounds concurrent async-http connections within that request.

Call the renderer from the normal Rails request path. The adapter chooses scheduler-scoped reuse whenever a `Fiber.scheduler` already exists before it enters `Sync {}`; custom middleware or background code that installs a scheduler with an unclear lifecycle can therefore keep renderer clients alive longer than intended. Keep those calls inside the request's scheduler lifecycle, or use the standard path where `Sync {}` creates and cleans up the per-request client.

`config.renderer_http_keep_alive_timeout` is **deprecated** and ignored: the async-http adapter manages connection lifecycle automatically (connections are reused within the scheduler and cleaned up when it ends). Explicitly setting it to a non-`nil` value in your `configure` block emits a deprecation warning; leaving it unset or setting it to `nil` is accepted silently. If you previously set it to `30` (the old default), remove the line from your `configure` block entirely.

To confirm reuse, compare before/after `responseEnd` timing and streamed RSC performance marks, and trace renderer sockets when you need to distinguish long-lived scheduler reuse from standard Puma's per-request scheduler cleanup.

## Need Help?

- **Pro Features:** [React on Rails Pro](../../pro/react-on-rails-pro.md)
- **Consulting:** [justin@shakacode.com](mailto:justin@shakacode.com)
