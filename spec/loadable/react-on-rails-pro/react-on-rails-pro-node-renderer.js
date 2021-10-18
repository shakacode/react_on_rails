const path = require('path');

// if using the proper install, use this:
// const {
//   reactOnRailsProNodeRenderer,
// } = require('@shakacode-tools/react-on-rails-pro-node-renderer')

const { reactOnRailsProNodeRenderer } = require('@shakacode-tools/react-on-rails-pro-node-renderer');

const env = process.env;

const config = {
  bundlePath: path.resolve(__dirname, '../tmp/bundles'),

  // Listen at RENDERER_PORT env value or default port 3800
  logLevel: env.RENDERER_LOG_LEVEL || 'info', // show all logs

  // See value in /config/initializers/react_on_rails_pro.rb. Should use env
  // value in real app.
  password: 'myPassword1',

  // Save bundle to "tmp/bundles" dir of our dummy app
  // This is the default
  port: env.RENDERER_PORT || 3800,

  // supportModules should be set to true to allow the server-bundle code to
  // see require, exports, etc.
  // `false` is like the ExecJS behavior
  // this option is required to equal `true` in order to use loadable components
  supportModules: true,

  // workersCount defaults to the number of CPUs minus 1
  workersCount: Number(process.env.VM_RENDERER_CONCURRENCY || 3),

  // Next 2 params, allWorkersRestartInterval and
  // delayBetweenIndividualWorkerRestarts must both should be set if you wish
  // to have automatic worker restarting, say to clear memory leaks.
  // time is in minutes between restarting all workers
  // Enable next 2 if the renderer is running out of memory
  // allWorkersRestartInterval: 15,
  // time in minutes between each worker restarting when restarting all workers
  // delayBetweenIndividualWorkerRestarts: 2,
};

// Renderer detects a total number of CPUs on virtual hostings like Heroku
// or CircleCI instead of CPUs number allocated for current container. This
// results in spawning many workers while only 1-2 of them really needed.
if (env.CI) {
  config.workersCount = 2;
}

reactOnRailsProNodeRenderer(config);
