# Node Renderer JavaScript Configuration

You can configure the node-renderer with only ENV values using the provided bin file `node-renderer`.

You can also create a custom configuration file to setup and launch the node-renderer.

The values in this file must be kept in sync with with the `config/initializers/react_on_rails_pro.rb` file, as documented in [Configuration](https://www.shakacode.com/react-on-rails-pro/docs/configuration/).

Here are the options available for the JavaScript renderer configuration object, as well as the available default ENV values if using the command line program node-renderer.

1. **port** (default: `process.env.RENDERER_PORT || 3800`) - The port renderer should listen to.
   If setting the port, you might want to ensure the port uses `process.env.PORT` so it will use port number provided by **Heroku** environment.
1. **logLevel** (default: `process.env.RENDERER_LOG_LEVEL || 'info'`) - Log lever for renderer. Set it to `'error'` to turn logging off. Available levels are: `{ error: 0, warn: 1, info: 2, verbose: 3, debug: 4, silly: 5 }`
1. **bundlePath** (default: `process.env.RENDERER_BUNDLE_PATH || '/tmp/react-on-rails-pro-node-renderer-bundles'` ) - path to temp directory where uploaded bundle files will be stored. For example you can set it to `path.resolve(__dirname, './.node-renderer-bundles')` if you configured renderer from the `/` directory of your app.
1. **workersCount** (default: `env.RENDERER_WORKERS_COUNT || defaultWorkersCount()` where default is your CPUs count - 1) - Number of workers that will be forked to serve rendering requests. If you set this manually make sure that value is a **Number** and is `>= 1`.
1. **password** (default: `env.RENDERER_PASSWORD`) - Password expected to receive form **Rails client** to authenticate rendering requests. If no password set, no authentication will be required.
1. **allWorkersRestartInterval** (default: `env.RENDERER_ALL_WORKERS_RESTART_INTERVAL`) - Interval in minutes between scheduled restarts of all cluster of workers. By default restarts are not enabled. If restarts are enabled, `delayBetweenIndividualWorkerRestarts` should also be set.
1. **delayBetweenIndividualWorkerRestarts** (default: `env.RENDERER_DELAY_BETWEEN_INDIVIDUAL_WORKER_RESTARTS`) - Interval in minutes between individual worker restarts (when cluster restart is triggered). By default restarts are not enabled. If restarts are enabled, `allWorkersRestartInterval` should also be set.
1. **supportModules** - (default: `env.RENDERER_SUPPORT_MODULES || null`) - If set to true, `supportModules` enables the server-bundle code to call a default set of NodeJS modules that get added to the VM context: `{ Buffer, process, setTimeout, setInterval, clearTimeout, clearInterval }`.
This option is required to equal `true` if you want to use loadable components
Setting this value to false causes the NodeRenderer to behave like ExecJS
1. **additionalContext** - (default: `null`) - additionalContext enables you to specify additional NodeJS modules to add to the VM context in addition to our supportModules defaults. Object shorthand notation may be used, but is not required.
Example: `{ URL, URLSearchParams, Crypto }`
1. **honeybadgerApiKey** - (default: `env.HONEYBADGER_API_KEY`) - If you want errors on the Node Renderer to be sent to Honeybadger, set this value and add package `@honeybadger-io/js`.
1. **sentryDsn**: - (default: `env.SENTRY_DSN || null`) - Enables server rendering errors catching with Sentry if the options is set. Add package `@sentry/node`.
1. **sentryTracing** - (default: `env.SENTRY_TRACING || null`) - Should be set to `true` to enable adding trace context to the error. Requires **sentryDsn** to be set.
1. **sentryTracesSampleRate** - (default: `env.SENTRY_TRACES_SAMPLE_RATE || 0.1`) - With this option set, every transaction created will have that percentage chance of being sent to Sentry. So, for example, if you set sentryTracesSampleRate to 0.2, approximately 20% of your transactions will get recorded and sent. See below for more details on Sentry Tracing. See [additional docs](https://www.shakacode.com/react-on-rails-pro/docs/node-renderer/error-reporting-and-tracing/).
1. **includeTimerPolyfills** - (default: `env.INCLUDE_TIMER_POLYFILLS || false`) - With this option set, use of `setTimeout`, `setInterval`, `clearTimeout`, &`clearInterval` functions will do nothing during server-rendering. This is useful when using dependancies like [react-virtuoso](https://github.com/petyosi/react-virtuoso) that use these functions during hydration. In RORP, hydration typically is synchronous and single-task, and thus callbacks passed to `setTimeout` should never run during server-side rendering. Because `setTimeout` is valid client-side, the functions are ignored on server-side rendering without errors or warnings.

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

// Renderer detects a total number of CPUs on virtual hostings like Heroku or CircleCI instead
// of CPUs number allocated for current container. This results in spawning many workers while
// only 1-2 of them really needed.
if (process.env.CI) {
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
