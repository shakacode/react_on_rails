const path = require('path');

// Use this for package installation test:
const reactOnRailsRenderer = require('react-on-rails-renderer');

// Use this for development:
// const reactOnRailsRenderer = require('../../../node_package/src/ReactOnRailsRenderer');

const config = {
  bundlePath: path.resolve(__dirname, '../tmp/bundles'),  // Save bundle to "tmp/" dir of our dummy app
  port: 3800,                                             // Listen at port 3800
};

reactOnRailsRenderer(config);
