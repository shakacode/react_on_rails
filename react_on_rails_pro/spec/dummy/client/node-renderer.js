const path = require('path');

const env = process.env;

// Use this for package installation test:
const { reactOnRailsProNodeRenderer } = require('@shakacode-tools/react-on-rails-pro-node-renderer');

const config = {
  bundlePath: path.resolve(__dirname, '../.node-renderer-bundles'), // Save bundle to "tmp/bundles" dir of our dummy app
  // This is the default
  port: env.RENDERER_PORT || 3800, // Listen at RENDERER_PORT env value or default port 3800
  logLevel: env.RENDERER_LOG_LEVEL || 'info',

  // See value in /config/initializers/react_on_rails_pro.rb. Should use env value in real app.
  password: 'myPassword1',

  // workersCount defaults to the number of CPUs minus 1

  // Next 2 params, allWorkersRestartInterval and delayBetweenIndividualWorkerRestarts must both
  // be set if you wish to have automatic worker restarting, say to clear memory leaks.

  // time in minutes between restarting all workers
  allWorkersRestartInterval: (env.CI && 2) || env.RENDERER_ALL_WORKERS_RESTART_INTERVAL || 10,

  // time in minutes between each worker restarting when restarting all workers
  delayBetweenIndividualWorkerRestarts: (env.CI && 0.01) || 1,

  // Uncomment and change value for testing the honeybadger API integration
  honeybadgerApiKey: 'a602365c',

  // This is a test account for React on Rails Pro.
  // Substitute your own DSN.
  // https://sentry.io/organizations/react-on-rails-pro/issues/?project=5591817
  // Only project contributors have access to see the test errors.
  sentryDsn: 'https://35ae284fec944acd89915dee2b9f3bc8@o504646.ingest.sentry.io/5591817',

  sentryTracing: true,

  sentryTracesSampleRate: 1,

  // supportModules should be set to true to allow the server-bundle code to see require, exports, etc.
  // false is like the ExecJS behavior
  // this option is required to equal `true` if you want to use loadable components
  supportModules: true,

  // Required to use setTimeout, setInterval, & clearTimeout during server rendering
  includeTimerPolyfills: false,
};

// Renderer detects a total number of CPUs on virtual hostings like Heroky or CircleCI instead
// of CPUs number allocated for current container. This results in spawning many workers while
// only 1-2 of them really needed.
if (env.CI) {
  config.workersCount = 2;
}

reactOnRailsProNodeRenderer(config);
