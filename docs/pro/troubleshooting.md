# Troubleshooting

For issues related to upgrading from GitHub Packages to public distribution, see the [Upgrading Guide](./updating.md).

## Streaming SSR request hangs indefinitely

**Symptom**: Requests to streaming pages (or RSC payload endpoints) hang forever and never complete.

**Cause**: A compression middleware (`Rack::Deflater`, `Rack::Brotli`) is configured with an `:if` condition that calls `body.each` to check the response size. This destructively consumes streaming chunks from the `SizedQueue`, causing a deadlock.

**Fix**: See the "Compression Middleware Compatibility" section in the [Streaming Server Rendering guide](../oss/building-features/streaming-server-rendering.md).

## Node Renderer

### Connection refused to renderer

**Symptom**: `Errno::ECONNREFUSED` or timeout errors when Rails tries to reach the node renderer.

**Fixes**:

- Verify the renderer is running: `curl http://localhost:3800/`
- Check that `config.renderer_url` in `config/initializers/react_on_rails_pro.rb` matches the renderer's actual port
- On Heroku, ensure the renderer is started via `Procfile.web` (see [Heroku deployment](../oss/building-features/node-renderer/heroku.md))

### Workers crashing with memory leaks

**Symptom**: Node renderer workers restart frequently or OOM.

**Fixes**:

- Enable rolling restarts with `allWorkersRestartInterval` and `delayBetweenIndividualWorkerRestarts` — use high values to avoid all workers being down simultaneously
- Profile memory using `node --inspect` (see [Profiling guide](./profiling-server-side-rendering-code.md))
- Check for global state leaks and use `config.ssr_pre_hook_js` to clear them

### Workers killed during streaming

**Symptom**: Streaming pages fail mid-stream when worker restarts are enabled.

**Fix**: Set `gracefulWorkerRestartTimeout` to a high value or disable it, so workers are not killed while serving active streaming requests.

## Fragment Caching

### Cache not being used

**Symptom**: `cached_react_component` always evaluates the props block.

**Fixes**:

- Verify Rails cache store is configured (not `:null_store`)
- Check `cache_key` values — if they change every request, the cache will never hit
- If your component depends on URL or locale, include those in the `cache_key` (see [Caching docs](../oss/building-features/caching.md))

### Stale cached content after deploy

**Symptom**: Components show old content after deploying new JavaScript bundles.

**Fix**: When `prerender: true` is set, the server bundle digest is automatically included in the cache key. If you're not prerendering, add your bundle hash to the cache key manually, or configure `dependency_globs` in `react_on_rails_pro.rb` to bust the cache on relevant file changes.

## License

### License validation fails on startup

**Symptom**: `ReactOnRailsPro::LicenseError` on Rails boot.

**Fixes**:

- Ensure `REACT_ON_RAILS_PRO_LICENSE` environment variable is set
- Check that the license key is not expired — contact [justin@shakacode.com](mailto:justin@shakacode.com) for renewal
- For evaluation/non-production use, a free license is available at [shakacode.com/react-on-rails-pro](https://www.shakacode.com/react-on-rails-pro/)

## React Server Components

### RSC payload endpoint returns 500

**Symptom**: The RSC payload route fails with an error.

**Fixes**:

- Verify `config.enable_rsc_support = true` in `config/initializers/react_on_rails_pro.rb`
- Check that `rsc_bundle_js_file`, `react_client_manifest_file`, and `react_server_client_manifest_file` are configured and the files exist
- Ensure the RSC webpack config is building correctly (3 bundles: client, server, RSC)

### Components not hydrating after streaming

**Symptom**: Server-rendered HTML appears but React doesn't hydrate on the client.

**Fixes**:

- Check that client-side JavaScript bundles are loaded (no 404s in browser console)
- Verify `immediate_hydration` option — set to `true` for immediate hydration
- Ensure client components have the `'use client'` directive
