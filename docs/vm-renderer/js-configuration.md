# VM Renderer JavaScript Configuration

You can configure the vm-renderer with only ENV values using the provided bin file `vm-renderer`.

You can also create a custom configuration file to setup and launch the vm-renderer.

The values in this file must be kept in sync with with the `config/initializers/react_on_rails_pro.rb` file, as documented in [docs/configuration.md](../configuration.md).

Here are the options available for the JavaScript renderer configuration object, as well as the available default ENV values if using the command line program vm-renderer.

1. **port** (default: `process.env.RENDERER_PORT || 3800`) - The port renderer should listen to. 
   If setting the port, you might want to ensure the port uses `process.env.PORT` so it will use port number provided by **Heroku** environment. 
1. **logLevel** (default: `process.env.RENDERER_LOG_LEVEL || 'info'`) - Log lever for renderer. Set it to `'error'` to turn logging off. Available levels are: `{ error: 0, warn: 1, info: 2, verbose: 3, debug: 4, silly: 5 }`
1. **bundlePath** (default: `process.env.RENDERER_BUNDLE_PATH || '/tmp/react-on-rails-pro-vm-renderer-bundles'` ) - path to temp directory where uploaded bundle files will be stored. For example you can set it to `path.resolve(__dirname, './tmp/bundles')` if you configured renderer from the `/` directory of your app. 
1. **workersCount** (default: `env.RENDERER_WORKERS_COUNT || defaultWorkersCount()` where default is your CPUs count - 1) - Number of workers that will be forked to serve rendering requests. If you set this manually make sure that value is a **Number** and is `>= 1`.
1. **password** (default: `env.RENDERER_PASSWORD`) - Password expected to receive form **Rails client** to authenticate rendering requests. If no password set, no authentication will be required.
1. **allWorkersRestartInterval** (default: `env.RENDERER_ALL_WORKERS_RESTART_INTERVAL`) - Interval in minutes between scheduled restarts of all cluster of workers. By default restarts are not enabled. If restarts are enabled, `delayBetweenIndividualWorkerRestarts` should also be set.
1. **delayBetweenIndividualWorkerRestarts** (default: `env.RENDERER_DELAY_BETWEEN_INDIVIDUAL_WORKER_RESTARTS`) - Interval in minutes between individual worker restarts (when cluster restart is triggered). By default restarts are not enabled. If restarts are enabled, `allWorkersRestartInterval` should also be set.
1. **honeybadgerApiKey** - (default: `env.HONEYBADGER_API_KEY`) - If you want errors on the VM Renderer to be sent to Honeybadger, set this value.
1. **supportModules** - (default: `env.RENDERER_SUPPORT_MODULES || null`) - Should be set to `true` to allow the server-bundle code to see require, exports, etc. `false` is like the ExecJS behavior.

## Example Launch Files

### Testing example: 

[spec/dummy/client/vm-renderer.js](../../spec/dummy/client/vm-renderer.js)

### Simple example:

Create a file './vm-renderer.js'
```js
import path from 'path';
import { reactOnRailsProVmRenderer } from 'react-on-rails-pro-vm-renderer';

const config = {
  // Save bundles to relative "./tmp/bundles" dir of our app 
  bundlePath: path.resolve(__dirname, './tmp/bundles'), 
  
  // All other values are the defaults, as described above 
};

// Renderer detects a total number of CPUs on virtual hostings like Heroku or CircleCI instead
// of CPUs number allocated for current container. This results in spawning many workers while
// only 1-2 of them really needed.
if (process.env.CI) {
  config.workersCount = 2;
}

reactOnRailsProVmRenderer(config);

```

And add this line to your `scripts` section of `package.json`

```json
  "scripts": {
    "start": "echo 'Starting React on Rails Pro VM Renderer.' && node ./vm-renderer.js"
  },
```

`yarn start` will run the renderer.
