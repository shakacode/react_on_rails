# VM Renderer JavaScript Configuration

You wil setup a file to launch the vm-renderer.

The values in this file must be kept in sync with with the `config/initializers/react_on_rails_pro.rb` file, as documented in [docs/configuration.md](../configuration.md).

Here are the options available for the JavaScript renderer configuration object:

1. **bundlePath** (default: `undefined`) - Relative path to temp directory where uploaded bundle files will be stored. For example you can set it to `path.resolve(__dirname, '../tmp/bundles')` if you configured renderer form `app/client` directory. Note: you **must** pass this parameter to configuration.
2. **port** (default: `process.env.PORT || 3800`) - The port renderer should listen to.
3. **logLevel** (default: `process.env.LOG_LEVEL || 'info'`) - Log lever for renderer. Set it to `'error'` to turn logging off. Available levels are: `{ error: 0, warn: 1, info: 2, verbose: 3, debug: 4, silly: 5 }`
4. **workersCount** (default: your CPUs number - 1) - Number of workers that will be forked to serve rendering requests. If you set this manually make sure that value is a **Number** and is `>= 1`.
5. **password** (default: `undefined`) - Password expected to receive form **Rails client** to authenticate rendering requests. If no password set, no authentication will be required.
6. **allWorkersRestartInterval** (default: `undefined`) - Interval in minutes between scheduled restarts of all cluster of workers. By default restarts are not enabled. If restarts are enabled, `delayBetweenIndividualWorkerRestarts` should also be set.
7. **delayBetweenIndividualWorkerRestarts** (default: `undefined`) - Interval in minutes between individual worker restarts (when cluster restart is triggered). By default restarts are not enabled. If restarts are enabled, `allWorkersRestartInterval` should also be set.

See the example below used in the `spec/dummy` sample app.



## Example Launch File
Used in Testing: [spec/dummy/client/vm-renderer.js](../../spec/dummy/client/vm-renderer.js).


```js
import path from 'path';
import reactOnRailsProVmRenderer from 'react-on-rails-pro-vm-renderer';

const env = process.env;

const config = {
  bundlePath: path.resolve(__dirname, '../tmp/bundles'),  // Save bundle to "tmp/" dir of our dummy app
  port: 3800,                                             // Listen at port 3800
  logLevel: env.LOG_LEVEL || 'debug',                     // Show all logs

  // See value in /config/initializers/react_on_rails_pro.rb. Should use env value in real app.
  password: 'myPassword1',

  // config.workersCount // Defaults to the number of CPUs minus 1

  // Next 2 params, allWorkersRestartInterval and delayBetweenIndividualWorkerRestarts must both
  // be set if you wish to have automatic worker restarting, say to clear memory leaks.

  // time in minutes between restarting all workers
  allWorkersRestartInterval: 2,

  // time in minutes between each worker restarting when restarting all workers
  delayBetweenIndividualWorkerRestarts: 1,
};

// Renderer detects a total number of CPUs on virtual hostings like Heroky or CircleCI instead
// of CPUs number allocated for current container. This results in spawning many workers while
// only 1-2 of them really needed.
if (process.env.CI) {
  config.workersCount = 2;
}

reactOnRailsProVmRenderer(config);

```
