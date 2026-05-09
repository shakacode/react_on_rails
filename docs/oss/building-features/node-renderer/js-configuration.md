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

## Runtime Globals for SSR and RSC

The node renderer executes uploaded JavaScript bundles inside isolated VM contexts. Those contexts do not automatically inherit every global from the host Node.js process.

| Runtime path              | Execution environment                 | Global guarantees                                                                                                                                                                                                                           |
| ------------------------- | ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Client bundle             | Browser                               | Browser APIs such as `window`, `document`, and browser `fetch` are available. Node.js globals are not.                                                                                                                                      |
| Server bundle (SSR)       | Node renderer VM context              | JavaScript built-ins are available. With the `supportModules` option enabled, common Node.js globals (`Buffer`, `TextDecoder`, `TextEncoder`, `URLSearchParams`, `ReadableStream`, `process`, `performance`, timer functions) are injected. |
| RSC bundle payload render | Node renderer VM context for RSC code | Uses the same VM context rules as the server bundle. The bundle is built for RSC, but host Node.js globals still need to be bundled, polyfilled, or injected.                                                                               |

`supportModules` does **not** inject `fetch`, `Headers`, `Request`, or `Response`. Even if the Node.js process that launches the renderer has those globals, code inside the renderer VM will not see them unless you provide them. That means Server Components should not assume that "modern Node" global `fetch` is available in the server or RSC bundle.

Prefer passing application data from Rails controllers through props when the data belongs to your Rails app. When a Server Component really needs to call an external HTTP API from the renderer, choose one of these approaches:

1. Inject host globals through `additionalContext`. On Node.js runtimes that already expose `globalThis.fetch`, start with the guarded example below so the renderer fails fast if any required fetch global is absent.
2. Import a server-side HTTP client in the component code, such as `node-fetch` v2 (CJS-compatible; v3+ is ESM-only) or `undici`, and let your bundler include it in the RSC/server bundle.

```js
const { reactOnRailsProNodeRenderer } = require('react-on-rails-pro-node-renderer');

const fetchImplementation = globalThis.fetch;
const HeadersImplementation = globalThis.Headers;
const RequestImplementation = globalThis.Request;
const ResponseImplementation = globalThis.Response;

if (!fetchImplementation || !HeadersImplementation || !RequestImplementation || !ResponseImplementation) {
  throw new Error(
    'Your Node.js runtime does not expose fetch, Headers, Request, and Response. ' +
      'Use a supported Node.js release that exposes these globals or replace the globalThis.* references above with a fetch polyfill import.',
  );
}

reactOnRailsProNodeRenderer({
  supportModules: true,
  additionalContext: {
    fetch: fetchImplementation,
    Headers: HeadersImplementation,
    Request: RequestImplementation,
    Response: ResponseImplementation,
  },
});
```

Install a fetch implementation only when your renderer runtime does not provide these globals, or when you intentionally want a bundled HTTP client instead of the host runtime's implementation. For CommonJS launch files, use a CJS-compatible implementation such as `node-fetch` v2 or an `undici` release compatible with your Node.js runtime; `node-fetch` v3+ is ESM-only. On supported Node.js LTS releases, use the latest `undici` release supported by your runtime; see [undici's compatibility notes](https://undici.nodejs.org/) for version pairing. If you maintain an older Node.js installation, pin the HTTP client to a version that still supports that runtime.

For example, with `node-fetch` v2 in a CommonJS launch file:

```js
const { reactOnRailsProNodeRenderer } = require('react-on-rails-pro-node-renderer');

const nodeFetch = require('node-fetch'); // node-fetch v2 (CJS)
const {
  Headers: HeadersImplementation,
  Request: RequestImplementation,
  Response: ResponseImplementation,
} = nodeFetch;

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

Use the same `additionalContext` shape if you import a compatible client from `undici` instead. Unlike `node-fetch` v2, `undici` exports `fetch` as a named export; choose a version compatible with your renderer Node.js runtime:

```js
const { reactOnRailsProNodeRenderer } = require('react-on-rails-pro-node-renderer');
const {
  fetch: fetchImplementation,
  Headers: HeadersImplementation,
  Request: RequestImplementation,
  Response: ResponseImplementation,
} = require('undici');

reactOnRailsProNodeRenderer({
  supportModules: true,
  additionalContext: {
    fetch: fetchImplementation,
    Headers: HeadersImplementation,
    Request: RequestImplementation,
    Response: ResponseImplementation,
  },
});
```

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

### Adding a Health Check Endpoint

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
