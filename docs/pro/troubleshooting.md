# Troubleshooting

For issues related to upgrading from GitHub Packages to public distribution, see the [Upgrading Guide](./updating.md).

## Streaming SSR request hangs indefinitely

**Symptom**: Requests to streaming pages (or RSC payload endpoints) hang forever and never complete.

**Cause**: A compression middleware (`Rack::Deflater`, `Rack::Brotli`) is configured with an `:if` condition that calls `body.each` to check the response size. This destructively consumes streaming chunks from the `SizedQueue`, causing a deadlock.

**Fix**: See the [Compression for Streamed RSC Responses](./streaming-ssr.md#compression-middleware-compatibility) section in the Streaming SSR guide.

## Node Renderer

### Connection refused to renderer

**Symptom**: `Errno::ECONNREFUSED` or timeout errors when Rails tries to reach the node renderer. In tests, this often surfaces as a generic **server-rendering error** — the actual root cause is that the renderer was unavailable when Rails connected to `REACT_RENDERER_URL`, not a webpack or bundle misconfiguration.

**Fixes**:

- Verify the renderer is running: `curl http://127.0.0.1:3800/`
- Check that `config.renderer_url` in `config/initializers/react_on_rails_pro.rb` matches the renderer's actual port
- Use the **same host literal** on both sides — prefer `127.0.0.1` over `localhost`. `RENDERER_HOST` defaults to `localhost`, which can resolve to IPv6 (`::1`) or IPv4 (`127.0.0.1`) depending on the machine's name-resolution order; if the renderer binds to one family and Rails dials the other, the connection is refused even though the renderer is running.
- In CI, make sure the renderer stays alive for the entire Rails test process — start it, wait for its port, run the tests, and clean up in the same step. See [Running Rails Tests Against the Node Renderer in CI](./node-renderer.md#running-rails-tests-against-the-node-renderer-in-ci).
- On Heroku, ensure the renderer is started via `Procfile.web` (see [Heroku deployment](../oss/building-features/node-renderer/heroku.md))

### Workers crashing with memory leaks

**Symptom**: Node renderer workers restart frequently or OOM. Memory grows monotonically over time.

**Root cause**: The Node Renderer reuses V8 VM contexts across requests. Any module-level state in your server bundle (caches, Sets, memoized functions) persists across all requests and can grow unboundedly. This is the most common cause of OOM in the Node Renderer.

**Immediate mitigations**:

- Set `NODE_OPTIONS=--max-old-space-size=<MB>` to cap V8 heap size and force more aggressive garbage collection
- Enable rolling restarts with `allWorkersRestartInterval` and `delayBetweenIndividualWorkerRestarts` — these periodically kill and restart workers, reclaiming all accumulated memory

**Investigation**:

- Capture heap snapshots with `NODE_OPTIONS="--heapsnapshot-signal=SIGUSR2"` — send `kill -USR2 <worker-pid>` at different times and compare in Chrome DevTools (see [Debugging guide](../oss/building-features/node-renderer/debugging.md#debugging-memory-leaks))
- Profile memory using `node --inspect` and Chrome DevTools (see [Profiling guide](./profiling-server-side-rendering-code.md))
- Search your server bundle code for module-level `Map`, `Set`, `{}` caches, and `_.memoize` calls — these are the most common leak sources
- Use `config.ssr_pre_hook_js` to run cleanup code before each render (e.g., clearing global state)
- See the [Memory Leaks guide](./js-memory-leaks.md) for detailed patterns, an audit checklist, and fixes

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

### License validation warnings on startup

**Symptom**: Rails logs a React on Rails Pro license warning or informational message on boot.

**Fixes**:

- In production, ensure `REACT_ON_RAILS_PRO_LICENSE` environment variable is set
- Run `bundle exec rake react_on_rails_pro:verify_license` to check license status (use `FORMAT=json` for CI/CD)
- Check that the license key is not expired — use [Pro pricing and sign up](https://pro.reactonrails.com/) or contact [justin@shakacode.com](mailto:justin@shakacode.com) for renewal
- Under ShakaCode Trust-Based Commercial Licensing, no token is required for evaluation or non-production use; the app runs in unlicensed mode

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
- Ensure client components have the `'use client'` directive
