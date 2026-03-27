const path = require('path');
const { reactOnRailsProNodeRenderer, parseWorkersCount } = require('react-on-rails-pro-node-renderer');

const { env } = process;
const configuredWorkersCount =
  parseWorkersCount(env.RENDERER_WORKERS_COUNT) ?? parseWorkersCount(env.NODE_RENDERER_CONCURRENCY);

const config = {
  serverBundleCachePath: path.resolve(__dirname, '../.node-renderer-bundles'),
  port: Number(env.RENDERER_PORT) || 3800,
  logLevel: env.RENDERER_LOG_LEVEL || 'info',

  // See value in /config/initializers/react_on_rails_pro.rb
  password: env.RENDERER_PASSWORD || 'devPassword',

  // Number of Node.js worker threads for SSR rendering
  // Set RENDERER_WORKERS_COUNT env var to override (e.g., for production tuning)
  // Set to 0 for single-process mode (useful for debugging).
  // Legacy fallback: NODE_RENDERER_CONCURRENCY
  workersCount: configuredWorkersCount ?? 3,

  // If set to true, `supportModules` enables the server-bundle code to call a default set of NodeJS modules
  // that get added to the VM context: { Buffer, process, setTimeout, setInterval, clearTimeout, clearInterval }.
  // This option is required to equal `true` if you want to use loadable components.
  // Setting this value to false causes the NodeRenderer to behave like ExecJS
  supportModules: true,

  // Additional Node.js globals to add to the VM context.
  additionalContext: { URL, AbortController },

  // Required to use setTimeout, setInterval, & clearTimeout during server rendering
  stubTimers: false,

  // Replay console logs from async server operations
  replayServerAsyncOperationLogs: true,
};

// Renderer detects a total number of CPUs on virtual hostings like Heroku or CircleCI instead
// of CPUs number allocated for current container. This results in spawning many workers while
// only 1-2 of them really needed.
if (env.CI && configuredWorkersCount == null) {
  config.workersCount = 2;
}

reactOnRailsProNodeRenderer(config);
