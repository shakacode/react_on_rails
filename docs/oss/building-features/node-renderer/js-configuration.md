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
1. **licenseToken** (default: `env.REACT_ON_RAILS_PRO_LICENSE`) - The paid React on Rails Pro license JWT.
   Explicit nonblank configuration takes precedence over the environment variable; blank or omitted configuration falls
   back to the environment. Configure this process separately from Rails when it runs as a standalone service. Token
   values are masked from sanitized renderer configuration logs.
1. **allWorkersRestartInterval** (default: `env.RENDERER_ALL_WORKERS_RESTART_INTERVAL`) - Interval in minutes between scheduled restarts of all workers. By default restarts are not enabled. If restarts are enabled, `delayBetweenIndividualWorkerRestarts` should also be set. **Recommended for production** — rolling restarts are the primary safety net against memory leaks from application code. See the [Memory Leaks guide](../../../pro/js-memory-leaks.md).
1. **delayBetweenIndividualWorkerRestarts** (default: `env.RENDERER_DELAY_BETWEEN_INDIVIDUAL_WORKER_RESTARTS`) - Interval in minutes between individual worker restarts (when cluster restart is triggered). By default restarts are not enabled. If restarts are enabled, `allWorkersRestartInterval` should also be set. Set this high enough so that not all workers are down simultaneously (e.g., if you have 4 workers and set this to 5 minutes, the full restart cycle takes 20 minutes).
1. **gracefulWorkerRestartTimeout**: (default: `env.GRACEFUL_WORKER_RESTART_TIMEOUT`) - Time in seconds that the master waits for a worker to gracefully restart (after serving all active requests) before killing it. For example, `30` means 30 seconds, not 30 milliseconds. Use this when you want to avoid situations where a worker gets stuck in an infinite loop and never restarts. This config is only usable if worker restart is enabled. The timeout starts when the worker should restart; if it elapses without a restart, the worker is killed.
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
1. **enableHealthEndpoints** - (default: `false`; set `RENDERER_ENABLE_HEALTH_ENDPOINTS` to `true`, `TRUE`, `yes`, `YES`, or `1` to enable) - If set to `true`, the renderer registers built-in, unauthenticated `GET /health` (liveness) and `GET /ready` (readiness) probe endpoints with status-only response bodies. See [Health and Readiness Endpoints](./health-checks.md) for semantics and working Kubernetes/ECS probe examples (the renderer's h2c listener cannot be probed with HTTP/1.1 `httpGet` probes).

Deprecated options:

1. **bundlePath** - Renamed to `serverBundleCachePath`. The old name will continue to work but will log a deprecation warning.
1. **honeybadgerApiKey**, **sentryDsn**, **sentryTracing**, **sentryTracesSampleRate** - Deprecated and have no effect.
   If you have any of them set, see [Error Reporting and Tracing](./error-reporting-and-tracing.md) for the new way to set up error reporting and tracing.
1. **includeTimerPolyfills** - Renamed to `stubTimers`.

## Runtime Globals for SSR and RSC

The node renderer executes uploaded JavaScript bundles inside isolated VM contexts. Those contexts do not automatically inherit every global from the host Node.js process.

| Runtime path              | Execution environment                 | Global guarantees                                                                                                                                                                                                                           |
| ------------------------- | ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Client bundle             | Browser                               | Browser APIs such as `window`, `document`, and browser `fetch` are available. Node.js globals are not.                                                                                                                                      |
| Server bundle (SSR)       | Node renderer VM context              | JavaScript built-ins are available. With the `supportModules` option enabled, common Node.js globals (`Buffer`, `TextDecoder`, `TextEncoder`, `URLSearchParams`, `ReadableStream`, `process`, `performance`, timer functions) are injected. |
| RSC bundle payload render | Node renderer VM context for RSC code | Uses the same VM context rules as the server bundle. The bundle is built for RSC, but host Node.js globals still need to be bundled, polyfilled, or injected.                                                                               |

`supportModules` injects a fixed set of common Node.js globals; it does **not** mirror the host global object into the VM. It does **not** inject `fetch`, `Headers`, `Request`, `Response`, `AbortController`, or `AbortSignal`. Even if the Node.js process that launches the renderer has those globals, code inside the renderer VM will not see them unless you provide them. That means Server Components should not assume that "modern Node" global `fetch` or fetch-related cancellation APIs are available in the server or RSC bundle.

> **Warning:** Passing `additionalContext: {}` (an empty object) still opts the renderer into CommonJS execution mode, where bundle code can call `require()` against the renderer host's module graph. If you do not need any injected globals, use `additionalContext: null` instead. See the [Bundle Architecture Reference](../../../pro/react-server-components/rendering-flow.md#bundle-architecture-reference) for the full security and behavioral implications.

Prefer passing application data from Rails controllers through props when the data belongs to your Rails app. When a Server Component really needs to call an external HTTP API from the renderer, choose one of these approaches:

1. Inject host globals through `additionalContext`. Node.js 18+ exposes `globalThis.fetch`, `Headers`, `Request`, and `Response` by default (Node.js 18 and 20 mark the fetch API as experimental; fetch became stable in Node.js 21 and remains stable in Node.js 22+ LTS). Start with the guarded example below so the renderer fails fast if any required fetch global is absent. On older or unsupported Node.js versions without these globals, use a bundled HTTP client instead (see option 2).
2. Import a server-side HTTP client in the component code, such as `undici` (recommended for new projects) or `node-fetch` v2 (CJS-compatible legacy fallback; v3+ is ESM-only; `node-fetch` v2 is maintenance-only since 2022, with security fixes only), and let your bundler include it in the RSC/server bundle.

```js
const { reactOnRailsProNodeRenderer } = require('react-on-rails-pro-node-renderer');

const fetchImplementation = globalThis.fetch;
const HeadersImplementation = globalThis.Headers;
const RequestImplementation = globalThis.Request;
const ResponseImplementation = globalThis.Response;
// Set to true only if your Server Components use AbortSignal; requires Node.js 15+.
const componentsUseAbortSignals = false;

if (!fetchImplementation || !HeadersImplementation || !RequestImplementation || !ResponseImplementation) {
  throw new Error(
    'Your Node.js runtime does not expose one or more required fetch globals (fetch, Headers, Request, Response). ' +
      'Use a supported Node.js release that exposes these globals or replace the globalThis.* references above with compatible fetch polyfill imports.',
  );
}

if (componentsUseAbortSignals && (!globalThis.AbortController || !globalThis.AbortSignal)) {
  throw new Error(
    'Your component code uses abort signals, but this Node.js runtime does not expose AbortController and AbortSignal. ' +
      'Use a runtime that exposes them or replace the globalThis.* references below with compatible abort polyfill imports.',
  );
}

reactOnRailsProNodeRenderer({
  supportModules: true,
  additionalContext: {
    fetch: fetchImplementation,
    Headers: HeadersImplementation,
    Request: RequestImplementation,
    Response: ResponseImplementation,
    ...(componentsUseAbortSignals
      ? {
          AbortController: globalThis.AbortController,
          AbortSignal: globalThis.AbortSignal,
        }
      : {}),
  },
});
```

Set `componentsUseAbortSignals` to `true` when component code creates or accepts `AbortSignal` values. That guard turns a missing `AbortController` or `AbortSignal` into a startup error; without it, the renderer would start and the first component that touches those globals would fail later with `ReferenceError`. If your components do not use abort signals, set it to `false` or omit those `additionalContext` entries. `supportModules` does not add abort globals.

Install a fetch implementation only when your renderer runtime does not provide these globals, or when you intentionally want a bundled HTTP client instead of the host runtime's implementation. Use this decision guide:

| Situation                                                                   | Recommendation                                                                                                                                                            |
| --------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Supported Node.js LTS host, want to use the runtime's built-in fetch        | Use the guarded `globalThis.fetch` / `additionalContext` example above.                                                                                                   |
| Supported Node.js LTS, ESM or CommonJS, want a bundled HTTP client          | Use `undici` and choose a release compatible with your runtime; see [undici's compatibility notes](https://github.com/nodejs/undici#long-term-support) for version pairs. |
| CommonJS launch file on an older runtime that does not expose fetch globals | Use `node-fetch` v2; `node-fetch` v3+ is ESM-only.                                                                                                                        |

For new projects, prefer `undici`. The `undici` example below is the primary bundled-client pattern; the `node-fetch` v2 example after it is a legacy fallback for older or unsupported Node.js installations.

Use the same `additionalContext` shape with `undici` as with the `globalThis.fetch` example above. Unlike `node-fetch` v2, `undici` exports `fetch` as a named export; choose a version compatible with your renderer Node.js runtime. Add the same startup guard so incompatible versions fail before the renderer starts. The example below uses CommonJS; ESM launchers can import the same names from `undici` and alias them to the `*Implementation` constants used here.

```js
const { reactOnRailsProNodeRenderer } = require('react-on-rails-pro-node-renderer');
const {
  fetch: fetchImplementation,
  Headers: HeadersImplementation,
  Request: RequestImplementation,
  Response: ResponseImplementation,
} = require('undici');

// `undici` does not export `AbortController`/`AbortSignal` as named exports
// (verified against v6 and v8 — they are absent from `Object.keys(require('undici'))`).
// Bundle code that uses abort signals relies on the host globals (Node.js 15+),
// injected via `additionalContext` below.
// Set to true only if your Server Components use AbortSignal; requires Node.js 15+.
const componentsUseAbortSignals = false;

if (!fetchImplementation || !HeadersImplementation || !RequestImplementation || !ResponseImplementation) {
  throw new Error(
    'The selected undici version does not expose one or more required fetch globals (fetch, Headers, Request, Response). ' +
      'Choose an undici release compatible with your renderer Node.js runtime.',
  );
}

if (componentsUseAbortSignals && (!globalThis.AbortController || !globalThis.AbortSignal)) {
  throw new Error(
    'Your component code uses abort signals, but this Node.js runtime does not expose AbortController and AbortSignal. ' +
      'Use Node.js 15+, or replace the globalThis.* references below with compatible abort polyfill imports.',
  );
}

reactOnRailsProNodeRenderer({
  supportModules: true,
  additionalContext: {
    fetch: fetchImplementation,
    Headers: HeadersImplementation,
    Request: RequestImplementation,
    Response: ResponseImplementation,
    ...(componentsUseAbortSignals
      ? {
          AbortController: globalThis.AbortController,
          AbortSignal: globalThis.AbortSignal,
        }
      : {}),
  },
});
```

For older or unsupported Node.js installations that cannot use a current `undici` release, fall back to `node-fetch` v2 in a CommonJS launch file:

```js
const { reactOnRailsProNodeRenderer } = require('react-on-rails-pro-node-renderer');

// node-fetch v2: the CJS default export is the fetch function itself.
// There is no named "fetch" export, so require("node-fetch").fetch is undefined.
// Headers, Request, and Response are attached as properties on that default export.
const nodeFetch = require('node-fetch');

// A successful require returns the fetch function; the guard below verifies
// the attached fetch classes that node-fetch v2 must provide.
const {
  Headers: HeadersImplementation,
  Request: RequestImplementation,
  Response: ResponseImplementation,
} = nodeFetch;

if (
  typeof nodeFetch !== 'function' ||
  !HeadersImplementation ||
  !RequestImplementation ||
  !ResponseImplementation
) {
  throw new Error(
    'node-fetch v2 did not expose the required fetch function or fetch classes (Headers, Request, Response). ' +
      'Ensure node-fetch v2 is installed; v3+ is ESM-only and will not work in this CommonJS launcher.',
  );
}

reactOnRailsProNodeRenderer({
  supportModules: true,
  additionalContext: {
    fetch: nodeFetch,
    Headers: HeadersImplementation,
    Request: RequestImplementation,
    Response: ResponseImplementation,
  },
});
```

`node-fetch` v2 does not ship its own `AbortController` or `AbortSignal` implementation, but `node-fetch` v2.6+ accepts spec-compatible signals when you provide them. If component code uses abort signals, merge the optional abort globals shown in the `globalThis.fetch` example into `additionalContext`; on Node.js 18+, the native `globalThis.AbortController` and `globalThis.AbortSignal` work with `node-fetch` v2.6+. On older EOL runtimes, use a compatible polyfill such as `node-abort-controller`.

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

  // Optional alternative to REACT_ON_RAILS_PRO_LICENSE. This application-defined
  // function can read from any secret provider available to the Node process.
  // licenseToken: loadLicenseTokenFromYourSecretManager(),

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

> **Built-in alternative:** The renderer now ships built-in `GET /health` (liveness) and `GET /ready` (readiness)
> endpoints behind the `enableHealthEndpoints` config option — no custom Fastify code required. See
> [Health and Readiness Endpoints](./health-checks.md). Use the recipe below only when you need custom probe logic
> (extra warm-up gates, dependency checks, or custom payloads).
> If your `configureFastify` callback already registers `/health` or `/ready`, remove or rename the custom route
> before enabling `enableHealthEndpoints`; Fastify raises a duplicate-route startup error for reused paths.
> If the duplicate route is registered by an async Fastify plugin during `app.register()` boot, Fastify reports its raw
> `FST_ERR_DUPLICATED_ROUTE` error instead of the `enableHealthEndpoints` migration hint.

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
set the status with `reply.code(503)`, and return a response object from that branch. Do not call `reply.send()` and
then return another response object.

```js
// Example: signal not-ready while application-specific warm-up runs.
// `workersReady` stands in for any per-worker readiness gate you maintain.
let workersReady = false;

configureFastify((app) => {
  // Fastify's `onReady` hook runs once per worker after all plugins finish
  // loading. Put any application warm-up here — preload modules, hydrate
  // caches, wait for an external dependency — and flip the flag when done.
  app.addHook('onReady', async () => {
    // await yourWarmUpFunction(); // put async warm-up logic here before flipping the flag
    workersReady = true;
  });

  app.get('/health', (request, reply) => {
    if (!workersReady) {
      reply.code(503);
      return { status: 'warming_up' };
    }
    return { status: 'ok' };
  });
});
```

The `-f` flag in `curl -sf` causes curl to exit non-zero for HTTP 4xx/5xx responses, so a `503` from this handler
correctly fails the probe. Kubernetes exec probes treat any non-zero curl exit code as a failure; the response body is
irrelevant to probe semantics, so you can return whatever payload is useful for debugging, such as
`{ status: 'ok', workers: 4 }`.

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

This section is the canonical source for probe semantics, recommended timing values, and curl command guidance. The
copy-paste YAML lives in
[Kubernetes Sidecar Manifest](./container-deployment.md#kubernetes-sidecar-manifest); update the values here first when
tuning, then reflect the change in the manifest.

Keep the three probe types distinct:

- **Startup** answers whether the renderer has finished booting. Separate it from readiness and liveness so slow startup
  does not cause premature restarts or block traffic.
- **Readiness** answers whether the renderer should receive new render requests. Use the built-in `/ready` endpoint
  only when an out-of-band warm-up render can compile a bundle before probe-gated traffic begins. Without that warm-up
  path, prefer a shallow TCP readiness check or the built-in `/info` endpoint, and use `/ready` for monitoring or
  post-deploy verification. See [Health and Readiness Endpoints](./health-checks.md) for the full cold-start semantics.
- **Liveness** answers whether the renderer is stuck badly enough that restarting the container is safer. Prefer
  `tcpSocket` as the default so transient CPU or GC pauses do not restart an otherwise recoverable renderer; use an
  h2c-aware `exec` check only when you intentionally need stricter hung-process detection.

Only the custom `/health` route requires `configureFastify`; `tcpSocket` probes and `/info` checks work without custom
Fastify setup. The health check route should return `200 OK` when the renderer is ready to serve requests, and return a
non-2xx status (for example `503`) only when the process should be marked unhealthy for the probe's purpose — readiness,
startup, or stricter liveness.

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
  with `initialDelaySeconds: 10` (first check fires at 10 s; the sixth and final check fires at
  `10 + ((6 - 1) * 5) = 35 s` after container start, and the restart follows once that check actually fails — up to
  `timeoutSeconds` later), `periodSeconds: 5`, `failureThreshold: 6`, and the Kubernetes default `timeoutSeconds: 1` for
  a TCP connection check.
- **Readiness (custom route)**: Use `exec` with
  `curl -sf --max-time 3 --http2-prior-knowledge http://localhost:3800/health` after registering the route with
  [`configureFastify`](#adding-a-health-check-endpoint). Start with `timeoutSeconds: 5`, `periodSeconds: 5`, and
  `failureThreshold: 3`.
- **Readiness (built-in info)**: Use `exec` with
  `curl -sf --max-time 3 --http2-prior-knowledge http://localhost:3800/info`. Use the same timing settings as the
  custom-route readiness probe. See the canonical [`/info` security note](#built-in-endpoints) for the unauthenticated-access caveat.
- **Readiness fallback**: Use `tcpSocket` on the renderer port only if curl with HTTP/2 support is unavailable. This
  checks port reachability, not application readiness.
- **Liveness**: Use `tcpSocket` on the renderer port as the default. Start with `timeoutSeconds: 1`,
  `periodSeconds: 10`, and `failureThreshold: 3`, matching the Container Deployment examples. Raise
  `failureThreshold`, and optionally `periodSeconds`, if hard listener checks restart the container too aggressively in
  your environment. `timeoutSeconds: 1` assumes a co-located probe over loopback; raise it (typically to `2`-`3`) when
  the renderer is reached over the network, such as the separate-workload topology.
- **Optional stricter liveness**: Use
  `curl -sf --max-time 3 --http2-prior-knowledge http://localhost:3800/info` only when you need liveness to catch a
  blocked event loop and have verified curl has HTTP/2 support in the image. Keep external dependency and warm-up checks
  in readiness, not liveness.

Substitute `3800` with your actual renderer port in Kubernetes YAML `exec` arrays; shell variable expansion
does not apply there. See the `port` option at the top of this page for Heroku or Control Plane.

> **Note (startup window):** With `initialDelaySeconds: 10`, `periodSeconds: 5`, and `failureThreshold: 6`:
>
> - First check fires at **10 s**.
> - Last (6th) check fires at **35 s** (`10 + (6 - 1) × 5`).
> - Container restarts after the 6th consecutive failure, up to `timeoutSeconds` (1 s here) later.
>
> If you omit `initialDelaySeconds`, checks start immediately and the last check fires at **25 s** (`(6 - 1) × 5`).
> Increase `failureThreshold` or `periodSeconds` if startup regularly takes longer. Reduce `initialDelaySeconds` if the
> renderer reliably opens its port within 1-2 s, or match it to your actual boot time to suppress noisy early-failure
> log entries during the warm-up window.

Readiness and liveness omit `initialDelaySeconds` here because Kubernetes 1.20+ (startup probe GA) defers them until
the startup probe succeeds. If you skip the startup probe or run an older cluster without startup probe support, add an
appropriate `initialDelaySeconds` to each.

See [Kubernetes Sidecar Manifest](./container-deployment.md#kubernetes-sidecar-manifest) for a complete pod spec with
all three probes wired in, and
[Startup Errors: `ERR_STREAM_PREMATURE_CLOSE`](./container-deployment.md#startup-errors-err_stream_premature_close) for
the startup-error troubleshooting context.

For Control Plane topology-specific `renderer_url`, host binding, and probe target guidance, see
[Control Plane Deployment Shapes](./container-deployment.md#control-plane-deployment-shapes).
