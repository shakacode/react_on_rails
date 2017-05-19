const path = require('path');
const reactOnRailsRenderer = require('./node_package/src/ReactOnRailsRenderer');

const config = {
  bundlePath: path.resolve(__dirname, './tmp/bundles'),
  port: process.env.PORT,
  logLevel: 'debug',
  password: process.env.AUTH_PASSWORD,
};

reactOnRailsRenderer(config);
