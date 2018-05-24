const path = require('path');

const env = process.env;

// Use this for package installation test:
const { reactOnRailsProVmRenderer } = require('react-on-rails-pro-vm-renderer');

const config = {
  bundlePath: path.resolve(__dirname, '../tmp/bundles'),  // Save bundle to "tmp/" dir of our dummy app
  // This is the default
  port: env.PORT || 3800,                         // Listen at PORT env value or default port 3800
  logLevel: env.LOG_LEVEL || 'info',              // Show all logs at debug level

  // See value in /config/initializers/react_on_rails_pro.rb. Should use env value in real app.
  password: 'myPassword1',

  // workersCount defaults to the number of CPUs minus 1

  // Next 2 params, allWorkersRestartInterval and delayBetweenIndividualWorkerRestarts must both
  // be set if you wish to have automatic worker restarting, say to clear memory leaks.

  // time in minutes between restarting all workers
  allWorkersRestartInterval: 2,

  // time in minutes between each worker restarting when restarting all workers
  delayBetweenIndividualWorkerRestarts: 0.01,
};

// Renderer detects a total number of CPUs on virtual hostings like Heroky or CircleCI instead
// of CPUs number allocated for current container. This results in spawning many workers while
// only 1-2 of them really needed.
if (env.CI) {
  config.workersCount = 2;
}

reactOnRailsProVmRenderer(config);
