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

## Custom Fastify Configuration

For advanced use cases, you can customize the Fastify server instance by importing the `master` and `worker` modules directly. This is useful for:

- Adding custom routes (e.g., `/health` for container health checks)
- Registering Fastify plugins
- Adding custom hooks for logging or monitoring

## Adding a Health Check Endpoint

When running the node-renderer in Docker or Kubernetes, you may need a `/health` endpoint for container health checks:

The advanced examples below use ES modules for readability. If you want this file to keep running
as `node renderer/node-renderer.js`, either keep using the CommonJS pattern shown in the simple
example above or switch the file to `.mjs` or `"type": "module"`.

```js
import masterRun from 'react-on-rails-pro-node-renderer/master';
import run, { configureFastify } from 'react-on-rails-pro-node-renderer/worker';
import cluster from 'cluster';

const config = {
  // Your configuration options here
};

// Register a custom health check route
configureFastify((app) => {
  app.get('/health', (request, reply) => {
    reply.send({ status: 'ok' });
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

## Configuring Startup, Readiness, and Liveness Probes

Use a cheap endpoint such as the `/health` route above for startup, readiness, and liveness probes. The health check route
should return `200 OK` when the process can accept probe traffic. The built-in `/info` route can also serve as a shallow
process check if you do not need a custom route; it is always registered by the renderer, does not require the renderer
password in any environment, and returns `node_version` and `renderer_version`.

Only the custom `/health` route requires `configureFastify`; `tcpSocket` probes and `/info` checks work without custom
Fastify setup.

> **Security note:** `/info` exposes runtime version details to anyone who can reach the renderer port. Keep the renderer
> on `localhost` or private networking, or add a custom `/health` route if you need a less revealing probe response.

Keep the probes' meanings separate:

- **Startup** answers whether the renderer has finished booting; keep it separate from liveness so slow startup does not
  cause premature restarts.
- **Readiness** answers whether the renderer should receive new render requests.
- **Liveness** answers whether the renderer is stuck badly enough that restarting the container is safer.

Do not put Rails, database, Redis, or other external dependency checks in the node-renderer's liveness probe. A
temporary dependency outage should not restart every renderer replica. If SSR must be available before Rails receives
traffic, make the Rails readiness endpoint perform a short renderer check.

The renderer listens with cleartext HTTP/2 (h2c). Do not configure a Kubernetes `httpGet` probe, Control Plane HTTP
probe, or any other HTTP/1.1-only probe directly against the renderer port; those probes are rejected by the h2c
listener. Use one of these probe styles instead:

| Probe style  | When to use it                                                                                                               |
| ------------ | ---------------------------------------------------------------------------------------------------------------------------- |
| `tcpSocket`  | Safe default for startup and liveness probes when you only need to know that the renderer port is accepting traffic.         |
| `exec` probe | Application-level readiness check with an h2c-aware client, for example `curl --http2-prior-knowledge`.                      |
| HTTP/1.1     | Only if you probe Rails, a separate HTTP/1.1 health sidecar/port, or another endpoint that is not the renderer h2c listener. |

> **Note:** The `exec` probe requires curl with HTTP/2 support. Verify with `curl --version | grep HTTP2`. If unavailable,
> use a `tcpSocket` readiness probe as a fallback.

Recommended starting values:

| Probe     | Starting point                                                                                                                                                                                                                                                                                                                                                   |
| --------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Startup   | `tcpSocket` on the renderer port (`3800` by default; use your configured `RENDERER_PORT` value if different, and see the `port` option at the top of this page for Heroku or Control Plane). Use `initialDelaySeconds: 10`, `periodSeconds: 5`, and `failureThreshold: 6` as a starting point.                                                                   |
| Readiness | `exec` with `curl -sf --http2-prior-knowledge http://localhost:3800/health` for a custom route, or `http://localhost:3800/info` if no custom route is configured. Use `timeoutSeconds: 5`, `periodSeconds: 5`, and `failureThreshold: 3`. Substitute `3800` with your actual port in Kubernetes YAML exec arrays; shell variable expansion does not apply there. |
| Liveness  | `tcpSocket` on the renderer port, `periodSeconds: 10`, and `failureThreshold: 3`, matching the Container Deployment examples. Increase only if your environment has slow storage or frequent transient pauses.                                                                                                                                                   |

See [Node Renderer: Container Deployment](./container-deployment.md#kubernetes-sidecar-manifest) for full
Kubernetes YAML examples, including startup, readiness, and liveness probes.

For Control Plane deployments, choose the probe target based on where the node renderer runs. Renderer probe targets
below mean `tcpSocket` or h2c-aware `exec` probes, not HTTP/1.1 `httpGet` probes directly against the renderer.

| Deployment shape                        | Rails `renderer_url`                                                                                                                                                                                                                                                                                                            | Renderer `host`             | Probe target                                                                                                                                                    |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Same Rails container/process supervisor | `http://localhost:3800`                                                                                                                                                                                                                                                                                                         | Default `localhost` is fine | Probe the `rails` container's Rails health endpoint, such as `/up` on port `3000`. Add a renderer check to Rails readiness if SSR is required.                  |
| Separate container in the same workload | `http://localhost:3800`                                                                                                                                                                                                                                                                                                         | Default `localhost` is fine | Add `tcpSocket` or h2c-aware `exec` probes to the `node-renderer` container on the renderer port. Binding to `0.0.0.0` also works if your platform requires it. |
| Separate node-renderer workload         | `http://node-renderer.<GVC_NAME>.cpln.local:3800` or your internal URL (`<GVC_NAME>` is your Control Plane Global Virtual Cloud name; generic format: `http://<WORKLOAD_NAME>.<GVC_NAME>.cpln.local:<PORT>`; see Control Plane's [service-to-service endpoint format](https://docs.controlplane.com/guides/service-to-service)) | `0.0.0.0`                   | Add `tcpSocket` or h2c-aware `exec` probes to the node-renderer workload container. Expose the renderer port internally, not publicly, unless required.         |

[Control Plane Flow](https://github.com/shakacode/control-plane-flow)'s default `rails` template models Rails as a
single-container standard workload. If you follow that template and run the renderer inside the Rails container,
configure the Rails workload's probes rather than looking for a separate node-renderer container. If you split the
renderer into its own container or workload, add renderer-specific probes there.

Control Plane configures probes per container. When Rails and the renderer share one container, use one combined Rails
health endpoint if you need to check both processes. For example, make the Rails readiness endpoint perform a short TCP
connection check to `localhost:3800` and return `503` if the renderer is unreachable. When the renderer has its own
container or workload, put the renderer probes on that container.

## Registering Fastify Plugins

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

## API Stability

The `./master` and `./worker` exports provide direct access to the node-renderer internals. While we strive to maintain backwards compatibility, these are considered advanced APIs. If you only need basic configuration, prefer using the standard `reactOnRailsProNodeRenderer` function with the configuration options documented above.
