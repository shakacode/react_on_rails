# Node Renderer JavaScript Configuration

> **Pro Feature** — Available with [React on Rails Pro](../../../pro/react-on-rails-pro.md).
> Free or very low cost for startups and small companies. [Upgrade or licensing details →](../../../pro/upgrading-to-pro.md#try-pro-risk-free)

You can configure the node-renderer entirely with ENV values from your own launch file or
`package.json` script. The package does not ship a standalone `node-renderer` CLI.

For most apps, create a small configuration file to set up and launch the node-renderer.

The values in this file must be kept in sync with the `config/initializers/react_on_rails_pro.rb` file, as documented in [Configuration](../../configuration/configuration-pro.md).

Here are the options available for the JavaScript renderer configuration object, as well as the
available default ENV values if you wire them into your own launch script.

[//]: # 'If you change text here, you may want to update comments in packages/node-renderer/src/shared/configBuilder.ts as well.'

1. **port** (default: `process.env.RENDERER_PORT || 3800`) - The port the renderer should listen to.
   [On Heroku](https://devcenter.heroku.com/articles/dyno-startup-behavior#port-binding-of-web-dynos) or [ControlPlane](https://docs.controlplane.com/reference/workload/containers#port-variable) you may want to use `process.env.PORT`.
1. **host** (default: `process.env.RENDERER_HOST || 'localhost'`) - The host/IP address the renderer should bind to.
   The default of `localhost` keeps the renderer reachable only from the local machine (or the same Kubernetes pod network namespace), following the same secure-by-default approach as PostgreSQL. Set to `0.0.0.0` only when the renderer must be reachable across a network boundary (e.g., separate container workloads in Docker Compose or Kubernetes).
   **Security caution:** The renderer executes JavaScript sent to it via `vm.runInContext()`, making it a remote code execution service by design. The Node.js `vm` module is [not a security boundary](https://nodejs.org/api/vm.html#vm-executing-javascript). Binding to `0.0.0.0` without `password` authentication exposes this to anyone on the network. Only bind to `0.0.0.0` behind private networking or firewall rules, and always set `password` when the renderer is network-accessible. See [Network Security](./basics.md#network-security) for details.
1. **logLevel** (default: `process.env.RENDERER_LOG_LEVEL || 'info'`) - The renderer log level. Set it to `silent` to turn logging off.
   [Available levels](https://getpino.io/#/docs/api?id=levels): `{ fatal: 60, error: 50, warn: 40, info: 30, debug: 20, trace: 10 }`. `silent` can be used as well.
1. **logHttpLevel** (default: `process.env.RENDERER_LOG_HTTP_LEVEL || 'error'`) - The HTTP server log level (same allowed values as `logLevel`).
1. **fastifyServerOptions** (default: `{}`) - Additional options to pass to the Fastify server factory. See [Fastify documentation](https://fastify.dev/docs/latest/Reference/Server/#factory).
1. **serverBundleCachePath** (default: `process.env.RENDERER_SERVER_BUNDLE_CACHE_PATH || process.env.RENDERER_BUNDLE_PATH || '/tmp/react-on-rails-pro-node-renderer-bundles'` ) - Path to a cache directory where uploaded server bundle files will be stored. This is distinct from Shakapacker's public asset directory. For example you can set it to `path.resolve(__dirname, './.node-renderer-bundles')` if you configured renderer from the `/` directory of your app.
1. **workersCount** (default: `process.env.RENDERER_WORKERS_COUNT || defaultWorkersCount()` where default is your CPUs count - 1) - Number of workers that will be forked to serve rendering requests. If you set this manually make sure that value is a **Number** and is `>= 0`. Setting this to `0` will run the renderer in a single process mode without forking any workers, which is useful for debugging purposes. For production use, the value should be `>= 1`.
1. **password** (default: `env.RENDERER_PASSWORD`) - The password expected to receive from the **Rails client** to authenticate rendering requests.
   In `development` and `test` environments (checked via both `NODE_ENV` and `RAILS_ENV`), the password is optional — if unset, no authentication is required.
   In all other environments (`staging`, `production`, etc.), the renderer will refuse to start without an explicit password. Set `RENDERER_PASSWORD` in your environment or pass `password` in the config object.
1. **allWorkersRestartInterval** (default: `env.RENDERER_ALL_WORKERS_RESTART_INTERVAL`) - Interval in minutes between scheduled restarts of all workers. By default restarts are not enabled. If restarts are enabled, `delayBetweenIndividualWorkerRestarts` should also be set. **Recommended for production** — rolling restarts are the primary safety net against memory leaks from application code. See the [Memory Leaks guide](../../../pro/js-memory-leaks.md).
1. **delayBetweenIndividualWorkerRestarts** (default: `env.RENDERER_DELAY_BETWEEN_INDIVIDUAL_WORKER_RESTARTS`) - Interval in minutes between individual worker restarts (when cluster restart is triggered). By default restarts are not enabled. If restarts are enabled, `allWorkersRestartInterval` should also be set. Set this high enough so that not all workers are down simultaneously (e.g., if you have 4 workers and set this to 5 minutes, the full restart cycle takes 20 minutes).
1. **gracefulWorkerRestartTimeout**: (default: `env.GRACEFUL_WORKER_RESTART_TIMEOUT`) - Time in seconds that the master waits for a worker to gracefully restart (after serving all active requests) before killing it. Use this when you want to avoid situations where a worker gets stuck in an infinite loop and never restarts. This config is only usable if worker restart is enabled. The timeout starts when the worker should restart; if it elapses without a restart, the worker is killed.
1. **maxDebugSnippetLength** (default: 1000) - If the rendering request is longer than this, it will be truncated in exception and logging messages.
1. **supportModules** - (default: `env.RENDERER_SUPPORT_MODULES || null`) - If set to true, `supportModules` enables the server-bundle code to call a default set of NodeJS global objects and functions that get added to the VM context:
   `{ Buffer, TextDecoder, TextEncoder, URLSearchParams, ReadableStream, process, performance, setTimeout, setInterval, setImmediate, clearTimeout, clearInterval, clearImmediate, queueMicrotask }`.
   `performance` is included so React 19's development build can call `performance.now()` from `React.lazy` without throwing `ReferenceError: performance is not defined`.
   This option is required to equal `true` if you want to use loadable components.
   Setting this value to false causes the NodeRenderer to behave like ExecJS.
   See also `stubTimers`.
1. **additionalContext** - (default: `null`) - additionalContext enables you to specify additional NodeJS objects (usually from https://nodejs.org/api/globals.html) to add to the VM context in addition to our `supportModules` defaults.
   Object shorthand notation may be used, but is not required.
   Example: `{ URL, Crypto }`
1. **stubTimers** - (default: `env.RENDERER_STUB_TIMERS` if that environment variable is set, `true` otherwise) - With this option set, use of functions `setTimeout`, `setInterval`, `setImmediate`, `clearTimeout`, `clearInterval`, `clearImmediate`, and `queueMicrotask` will do nothing during server-rendering.
   This is useful when using dependencies like [react-virtuoso](https://github.com/petyosi/react-virtuoso) that use these functions during hydration.
   In RORP, hydration typically is synchronous and single-task (unless you use streaming) and thus callbacks passed to task-scheduling functions should never run during server-side rendering.
   Because these functions are valid client-side, they are ignored on server-side rendering without errors or warnings.
   Note that `performance` (exposed when `supportModules: true`) is the host's real `performance` object and is **not** stubbed by `stubTimers`; if rendered output embeds `performance.now()` values (e.g., dev-only timing annotations) they will vary between renders. Override via `additionalContext` (e.g., `{ performance: { now: () => 0 } }`) if strict SSR determinism is required.
   See also `supportModules`.

Deprecated options:

1. **bundlePath** - Renamed to `serverBundleCachePath`. The old name will continue to work but will log a deprecation warning.
1. **honeybadgerApiKey**, **sentryDsn**, **sentryTracing**, **sentryTracesSampleRate** - Deprecated and have no effect.
   If you have any of them set, see [Error Reporting and Tracing](./error-reporting-and-tracing.md) for the new way to set up error reporting and tracing.
1. **includeTimerPolyfills** - Renamed to `stubTimers`.

## Example Launch Files

### Testing example:

The repository's dummy app keeps a full integration-test launcher at
[`react_on_rails_pro/spec/dummy/renderer/node-renderer.js`](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails_pro/spec/dummy/renderer/node-renderer.js).

### Simple example:

Create a file `renderer/node-renderer.js`. The generator uses this filename and CommonJS syntax so
the file runs directly with `node renderer/node-renderer.js` without extra ESM configuration.

```js
const path = require('path');
const { reactOnRailsProNodeRenderer } = require('react-on-rails-pro-node-renderer');

const config = {
  // Save bundles to relative "./.node-renderer-bundles" dir of our app root
  serverBundleCachePath: path.resolve(__dirname, '../.node-renderer-bundles'),

  // All other values are the defaults, as described above
};

// For debugging, run in single process mode
if (process.env.NODE_ENV === 'development') {
  config.workersCount = 0;
}
// Renderer detects a total number of CPUs on virtual hostings like Heroku or CircleCI instead
// of CPUs number allocated for current container. This results in spawning many workers while
// only 1-2 of them really needed.
else if (process.env.CI) {
  config.workersCount = 2;
}

reactOnRailsProNodeRenderer(config);
```

And add a root-level script to the `scripts` section of your `package.json`

```json
  "scripts": {
    "node-renderer": "node renderer/node-renderer.js"
  },
```

Run the renderer with `pnpm run node-renderer` (or the equivalent `npm`/`yarn` command for your app).

## Built-in Endpoints

The React on Rails Pro node renderer registers `/info` as a plain `GET` route outside the authenticated render and asset
endpoints, and it does not use the render or asset authentication prechecks, so it remains accessible without the renderer
password even when `password` is configured. The route returns `node_version` and `renderer_version`. Treat it as a
shallow process check and keep the renderer on `localhost` or private networking if those runtime version details should
not be exposed.

Verify it locally:

```bash
curl -s --http2-prior-knowledge http://localhost:3800/info
```

Example response:

```json
{
  "node_version": "v20.17.0",
  "renderer_version": "1.4.2"
}
```

## Custom Fastify Configuration

For advanced use cases, such as adding custom routes, registering Fastify plugins, or hooking into the request lifecycle,
you can configure the Fastify server directly by importing the `master` and `worker` modules instead of using
`reactOnRailsProNodeRenderer`.

The advanced examples below use ES modules for readability. If you want this file to keep running
as `node renderer/node-renderer.js`, either keep using the CommonJS pattern shown in the simple
example above or switch the file to `.mjs` or `"type": "module"`.

### Adding a Health Check Endpoint

A common need is a `/health` endpoint for container health checks:

```js
import masterRun from 'react-on-rails-pro-node-renderer/master';
import run, { configureFastify } from 'react-on-rails-pro-node-renderer/worker';
import cluster from 'cluster';

const config = {
  // Your configuration options here
};

// Register a custom health check route
configureFastify((app) => {
  app.get('/health', () => {
    // Return a Promise or use async/await if warm-up checks involve async operations.
    return { status: 'ok' };
  });
});

// The node-renderer uses Node.js cluster module to fork worker processes.
// The primary process manages workers; workers handle HTTP requests.
if (cluster.isPrimary) {
  masterRun(config);
} else {
  run(config);
}
```

The sample `/health` route is intentionally shallow and omits handler parameters because it does not need them. Fastify
also passes `request` and `reply` to handlers if you need to inspect headers, set status codes, or customize the
response. Add warm-up or readiness-gate logic inside this handler if readiness should wait for renderer-specific
initialization. To signal not-ready while keeping Fastify's return-value style, add `reply` to the handler parameters,
set the status with `reply.code(503)`, and return `{ status: 'warming_up' }` from that branch. Do not call `reply.send()`
and then return another response object. The `-f` flag in `curl -sf` causes curl to exit non-zero for HTTP 4xx/5xx
responses, so a `503` from this handler correctly fails the probe. Kubernetes exec probes treat any non-zero curl exit
code as a failure; the response body is irrelevant to probe semantics, so you can return whatever payload is useful for
debugging, such as `{ status: 'ok', workers: 4 }`.

Routes registered with `configureFastify` do not automatically use the renderer's render and asset authentication
prechecks. A custom `/health` route like the one above is reachable without the renderer password unless you add your own
Fastify authentication. Keep probe routes shallow and non-sensitive, and keep the renderer on `localhost` or private
networking.

### Registering Fastify Plugins

You can also register Fastify plugins. This example assumes you're using the same cluster setup pattern shown above:

```js
// In the worker branch of your cluster setup (see example above)
import run, { configureFastify } from 'react-on-rails-pro-node-renderer/worker';
import cors from '@fastify/cors';

configureFastify((app) => {
  // Register a plugin
  app.register(cors, {
    origin: true,
  });
});

// Add request logging
configureFastify((app) => {
  app.addHook('onRequest', (request, reply, done) => {
    try {
      console.log(`Request: ${request.method} ${request.url}`);
      done();
    } catch (err) {
      done(err);
    }
  });
});
```

> **Note:** The `configureFastify` function must be called before calling `run()`. Multiple callbacks can be registered and will execute in order. You can use `app.ready()` in your callback to ensure all plugins are loaded before performing operations that depend on them.

### API Stability

The `./master` and `./worker` exports provide direct access to the node-renderer internals. While we strive to maintain backwards compatibility, these are considered advanced APIs. If you only need basic configuration, prefer using the standard `reactOnRailsProNodeRenderer` function with the configuration options documented above.

## Configuring Startup, Readiness, and Liveness Probes

Keep the three probe types distinct:

- **Startup** answers whether the renderer has finished booting. Separate it from readiness and liveness so slow startup
  does not cause premature restarts or block traffic.
- **Readiness** answers whether the renderer should receive new render requests. Use an application-level endpoint such
  as the `/health` route in [Adding a Health Check Endpoint](#adding-a-health-check-endpoint), or the built-in `/info`
  endpoint for a shallow process check.
- **Liveness** answers whether the renderer is stuck badly enough that restarting the container is safer. Prefer
  `tcpSocket` as the default so transient CPU or GC pauses do not restart an otherwise recoverable renderer; use an
  h2c-aware `exec` check only when you intentionally need stricter hung-process detection.

Only the custom `/health` route requires `configureFastify`; `tcpSocket` probes and `/info` checks work without custom
Fastify setup. The health check route should return `200 OK` when the process can accept probe traffic.

> **Security note:** See [Built-in Endpoints](#built-in-endpoints) for the note on `/info` exposing runtime version
> details.

Do not put Rails, database, Redis, or other external dependency checks in the node-renderer's liveness probe. A
temporary dependency outage should not restart every renderer replica. If SSR must be available before Rails receives
traffic, make the Rails readiness endpoint perform a short renderer check.

The renderer listens with cleartext HTTP/2 (h2c). Do not configure a Kubernetes `httpGet` probe, Control Plane HTTP
probe, or any other HTTP/1.1-only probe directly against the renderer port; those probes are rejected by the h2c
listener. Use one of these probe styles instead:

| Probe style  | When to use it                                                                                                                      |
| ------------ | ----------------------------------------------------------------------------------------------------------------------------------- |
| `tcpSocket`  | Startup checks, default liveness checks, and fallback readiness when curl with HTTP/2 support is unavailable.                       |
| `exec` probe | Application-level readiness and optional stricter liveness checks with an h2c-aware client, such as `curl --http2-prior-knowledge`. |
| HTTP/1.1     | Only if you probe Rails, a separate HTTP/1.1 health sidecar/port, or another endpoint that is not the renderer h2c listener.        |

A passing `tcpSocket` probe means the h2c listener has bound to the port; cluster workers might still be warming up.
Keep an application-level readiness probe if traffic should wait for worker initialization.

For Kubernetes and platform `tcpSocket` probes, set the renderer `host` to `0.0.0.0` because those probes connect to the
pod or workload IP, not container-local loopback. The default `localhost` binding is fine for `exec` probes that run
inside the renderer container.

For liveness, start with `tcpSocket`. A fully blocked Node.js event loop may still accept TCP connections and pass that
check, so use an h2c-aware `exec` liveness probe with a short `--max-time` only if you explicitly need stricter
hung-process detection and have verified curl HTTP/2 support in the image.

> **Note:** The `exec` probe requires curl with HTTP/2 support. Verify with `curl --version | grep -i http2`. If unavailable,
> use a `tcpSocket` probe as a fallback.

Recommended starting values:

- **Startup**: Use `tcpSocket` on the renderer port (`3800` by default; use your configured `RENDERER_PORT` value if
  different). TCP is enough here because readiness below gates traffic; startup only shields liveness during boot. Start
  with `initialDelaySeconds: 10` (first check fires at 10 s; the sixth and final failure fires at
  `10 + ((6 - 1) * 5) = 35 s` after container start), `periodSeconds: 5`, `failureThreshold: 6`, and the Kubernetes
  default `timeoutSeconds: 1` for a TCP connection check.
- **Readiness (custom route)**: Use `exec` with
  `curl -sf --max-time 3 --http2-prior-knowledge http://localhost:3800/health` after registering the route with
  [`configureFastify`](#adding-a-health-check-endpoint). Start with `timeoutSeconds: 5`, `periodSeconds: 5`, and
  `failureThreshold: 3`.
- **Readiness (built-in info)**: Use `exec` with
  `curl -sf --max-time 3 --http2-prior-knowledge http://localhost:3800/info`. Use the same timing settings as the
  custom-route readiness probe. `/info` is unauthenticated and exposes runtime version details; see the
  [security note](#built-in-endpoints) and keep the renderer on private networking.
- **Readiness fallback**: Use `tcpSocket` on the renderer port only if curl with HTTP/2 support is unavailable. This
  checks port reachability, not application readiness.
- **Liveness**: Use `tcpSocket` on the renderer port as the default. Start with `timeoutSeconds: 1`,
  `periodSeconds: 10`, and `failureThreshold: 3`, matching the Container Deployment examples. Raise
  `failureThreshold`, and optionally `periodSeconds`, if hard listener checks restart the container too aggressively in
  your environment.
- **Optional stricter liveness**: Use
  `curl -sf --max-time 3 --http2-prior-knowledge http://localhost:3800/info` only when you need liveness to catch a
  blocked event loop and have verified curl has HTTP/2 support in the image. Keep external dependency and warm-up checks
  in readiness, not liveness.

Substitute `3800` with your actual renderer port in Kubernetes YAML `exec` arrays; shell variable expansion
does not apply there. See the `port` option at the top of this page for Heroku or Control Plane.

> **Note (startup window):** With these values, the first check fires at `initialDelaySeconds` (10 s), then every
> `periodSeconds` (5 s) thereafter, and the container restarts only if all six consecutive startup checks fail. Increase
> `failureThreshold` or `periodSeconds` if startup regularly takes longer.
> The 10-second initial delay only shifts when the first check fires. Omitting it starts checks immediately; the
> failure window still comes from `failureThreshold * periodSeconds`. Reduce `initialDelaySeconds` if your renderer
> reliably opens the port within 1-2 seconds, or keep it to avoid noisy early-failure log entries.

Readiness and liveness omit `initialDelaySeconds` here because Kubernetes 1.20+ (startup probe GA) defers them until
the startup probe succeeds. If you skip the startup probe or run an older cluster without startup probe support, add an
appropriate `initialDelaySeconds` to each.

See [Node Renderer: Container Deployment](./container-deployment.md#startup-errors-err_stream_premature_close) for full
Kubernetes YAML examples and the shared probe command notes for curl HTTP/2 support, `--max-time` buffers, and
`initialDelaySeconds` guidance.

For Control Plane topology-specific `renderer_url`, host binding, and probe target guidance, see
[Control Plane Deployment Shapes](./container-deployment.md#control-plane-deployment-shapes).
