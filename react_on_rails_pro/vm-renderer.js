const path = require('path');
const reactOnRailsProVmRenderer = require('./node_package/src/ReactOnRailsProVmRenderer');

const config = {
  bundlePath: path.resolve(__dirname, './tmp/bundles'),
  port: process.env.PORT,
  logLevel: 'debug',
  password: process.env.AUTH_PASSWORD,

  // Uncomment to enable scheduled worker restarts (both params required)
  // allWorkersRestartInterval: 6 * 60, // in minutes
  // delayBetweenIndividualWorkerRestarts: 5, // in minutes
};

reactOnRailsProVmRenderer(config);
