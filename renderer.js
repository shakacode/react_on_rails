const path = require('path');
const reactOnRailsRenderer = require('./node_package/src/ReactOnRailsRenderer');

const config = {
  bundlePath: path.resolve(__dirname, './tmp/bundles'),
  port: process.env.PORT,
  logLevel: 'debug',
  password: process.env.AUTH_PASSWORD,
  // allWorkersRestartInterval: 6 * 60, // in minutes
  // delayBetweenIndividualWorkersRestarts: 5, // in minutes
};

reactOnRailsRenderer(config);
