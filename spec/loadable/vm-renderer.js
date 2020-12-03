const path = require('path');

// Use this for package installation test:
const { reactOnRailsProNodeRenderer } = require('@shakacode-tools/react-on-rails-pro-node-renderer');

const config = {
  // tmp/bundles path must be kept in sync with /lib/tasks/asset.raie
  bundlePath: path.resolve(__dirname, './tmp/bundles'), // Save bundle to "tmp/" dir of our dummy app

  // For production, we want process.env.PORT
  port: process.env.PORT || 3800,

  logLevel: process.env.VM_RENDERER_DEBUG_LEVEL || 'debug', // Show all logs
  workersCount: Number(process.env.VM_RENDERER_CONCURRENCY || 3),
  // If the renderer is running out of memory, enable these below.
  // Note, Heroku restarts the renderer every day: https://devcenter.heroku.com/articles/dynos#restarting
  // allWorkersRestartInterval: 15, // in minutes
  // delayBetweenIndividualWorkerRestarts: 2, // in minutes

  supportModules: true,
};

// Renderer detects a total number of CPUs on virtual hostings like Heroky or CircleCI instead
// of CPUs number allocated for current container. This results in spawning many workers while
// only 1-2 of them really needed.
if (process.env.CI) {
  config.workersCount = 2;
}

reactOnRailsProNodeRenderer(config);
