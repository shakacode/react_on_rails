# Node Renderer JavaScript Configuration

You can configure the node-renderer with only ENV values using the provided bin file `node-renderer`.

You can also create a custom configuration file to setup and launch the node-renderer.

The values in this file must be kept in sync with with the `config/initializers/react_on_rails_pro.rb` file, as documented in [Configuration](../configuration.md).

Here are the options available for the JavaScript renderer configuration object, as well as the available default ENV values if using the command line program node-renderer.

[//]: # (If you change text here, you may want to update comments in packages/node-renderer/src/shared/configBuilder.ts as well.)

1. **port** (default: `process.env.RENDERER_PORT || 3800`) - The port the renderer should listen to.
[On Heroku](https://devcenter.heroku.com/articles/dyno-startup-behavior#port-binding-of-web-dynos) or [ControlPlane](https://docs.controlplane.com/reference/workload/containers#port-variable) you may want to use `process.env.PORT`.
1. **logLevel** (default: `process.env.RENDERER_LOG_LEVEL || 'info'`) - The renderer log level. Set it to `silent` to turn logging off.
[Available levels](https://getpino.io/#/docs/api?id=levels): `{ fatal: 60, error: 50, warn: 40, info: 30, debug: 20, trace: 10 }`. `silent` can be used as well.
1. **logHttpLevel** (default: `process.env.RENDERER_LOG_HTTP_LEVEL || 'error'`) - The HTTP server log level (same allowed values as `logLevel`).
1. **fastifyServerOptions** (default: `{}`) - Additional options to pass to the Fastify server factory. See [Fastify documentation](https://fastify.dev/docs/latest/Reference/Server/#factory).
1. **bundlePath** (default: `process.env.RENDERER_BUNDLE_PATH || '/tmp/react-on-rails-pro-node-renderer-bundles'` ) - path to a temp directory where uploaded bundle files will be stored. For example you can set it to `path.resolve(__dirname, './.node-renderer-bundles')` if you configured renderer from the `/` directory of your app.
1. **workersCount** (default: `process.env.RENDERER_WORKERS_COUNT || defaultWorkersCount()` where default is your CPUs count - 1) - Number of workers that will be forked to serve rendering requests. If you set this manually make sure that value is a **Number** and is `>= 0`. Setting this to `0` will run the renderer in a single process mode without forking any workers, which is useful for debugging purposes. For production use, the value should be `>= 1`.
1. **password** (default: `env.RENDERER_PASSWORD`) - The password expected to receive from the **Rails client** to authenticate rendering requests.
If no password is set, no authentication will be required.
1. **allWorkersRestartInterval** (default: `env.RENDERER_ALL_WORKERS_RESTART_INTERVAL`) - Interval in minutes between scheduled restarts of all workers. By default restarts are not enabled. If restarts are enabled, `delayBetweenIndividualWorkerRestarts` should also be set.
1. **delayBetweenIndividualWorkerRestarts** (default: `env.RENDERER_DELAY_BETWEEN_INDIVIDUAL_WORKER_RESTARTS`) - Interval in minutes between individual worker restarts (when cluster restart is triggered). By default restarts are not enabled. If restarts are enabled, `allWorkersRestartInterval` should also be set.
1. **gracefulWorkerRestartTimeout**: (default: `env.GRACEFUL_WORKER_RESTART_TIMEOUT`) - Time in seconds that master waits for worker to gracefully restart (after serving all active requests) before killing it. You need to use this config to avoid situations where worker stucks at an inifite loop and doesn't restart. This config is only usable if worker restart is enabled. This time is counted starting from the time when should the worker restart, if that timeout value passed without restarting the worker, the worker is killed.
1. **maxDebugSnippetLength** (default: 1000) - If the rendering request is longer than this, it will be truncated in exception and logging messages.
1. **supportModules** - (default: `env.RENDERER_SUPPORT_MODULES || null`) - If set to true, `supportModules` enables the server-bundle code to call a default set of NodeJS global objects and functions that get added to the VM context: 
`{ Buffer, TextDecoder, TextEncoder, URLSearchParams, ReadableStream, process, setTimeout, setInterval, setImmediate, clearTimeout, clearInterval, clearImmediate, queueMicrotask }`.
This option is required to equal `true` if you want to use loadable components.
Setting this value to false causes the NodeRenderer to behave like ExecJS.
See also `stubTimers`.
1. **additionalContext** - (default: `null`) - additionalContext enables you to specify additional NodeJS objects (usually from https://nodejs.org/api/globals.html) to add to the VM context in addition to our `supportModules` defaults. 
Object shorthand notation may be used, but is not required.
Example: `{ URL, Crypto }`
1. **stubTimers** - (default: `env.RENDERER_STUB_TIMERS` if that environment variable is set, `true` otherwise) - With this option set, use of functions `setTimeout`, `setInterval`, `setImmediate`, `clearTimeout`, `clearInterval`, `clearImmediate`, and `queueMicrotask` will do nothing during server-rendering. 
This is useful when using dependencies like [react-virtuoso](https://github.com/petyosi/react-virtuoso) that use these functions during hydration.
In RORP, hydration typically is synchronous and single-task (unless you use streaming) and thus callbacks passed to  task-scheduling functions should never run during server-side rendering.
Because these functions are valid client-side, they are ignored on server-side rendering without errors or warnings.
See also `supportModules`.

Deprecated options:

1. **honeybadgerApiKey**, **sentryDsn**, **sentryTracing**, **sentryTracesSampleRate** - Deprecated and have no effect. 
If you have any of them set, see [Error Reporting and Tracing](./error-reporting-and-tracing.md) for the new way to set up error reporting and tracing.
1. **includeTimerPolyfills** - Renamed to `stubTimers`.

## Example Launch Files

### Testing example:

[spec/dummy/client/node-renderer.js](https://github.com/shakacode/react_on_rails_pro/blob/master/spec/dummy/client/node-renderer.js)

### Simple example:

Create a file './node-renderer.js'
```js
import path from 'path';
import { reactOnRailsProNodeRenderer } from '@shakacode-tools/react-on-rails-pro-node-renderer';

const config = {
  // Save bundles to relative "./.node-renderer-bundles" dir of our app
  bundlePath: path.resolve(__dirname, './.node-renderer-bundles'),

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

And add this line to your `scripts` section of `package.json`

```json
  "scripts": {
    "start": "echo 'Starting React on Rails Pro Node Renderer.' && node ./node-renderer.js"
  },
```

`yarn start` will run the renderer.
