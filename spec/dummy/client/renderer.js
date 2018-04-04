const path = require('path');

// Use this for package installation test:
const reactOnRailsRenderer = require('react-on-rails-renderer');

// Use this for development:
// const reactOnRailsRenderer = require('../../../node_package/src/ReactOnRailsRenderer');

const config = {
  bundlePath: path.resolve(__dirname, '../tmp/bundles'),  // Save bundle to "tmp/" dir of our dummy app
  port: 3800,                                             // Listen at port 3800
  logLevel: 'debug',                                      // Show all logs
};

// Renderer detects a total number of CPUs on virtual hostings like Heroky or CircleCI instead
// of CPUs number allocated for current container. This results in spawning many workers while
// only 1-2 of them really needed.
if (process.env.CI) {
  config.workersCount = 2;
}

reactOnRailsRenderer(config);
