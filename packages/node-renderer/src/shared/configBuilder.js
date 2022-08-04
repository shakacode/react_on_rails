/**
 * Reads CLI arguments and build the config.
 *
 * @module worker/configBuilder
 */
const os = require('os');
const log = require('./log');
const requireOptional = require('./requireOptional');
const { configureLogger } = require('./log');
const errorReporter = require('./errorReporter');
const tracing = require('./tracing');
const packageJson = require('./packageJson');
const truthy = require('./truthy');

const Sentry = requireOptional('@sentry/node');

const DEFAULT_TMP_DIR = '/tmp/react-on-rails-pro-node-renderer-bundles';
// usually remote renderers are on staging or production, so, use production folder always
const DEFAULT_PORT = 3800;
const DEFAULT_LOG_LEVEL = 'info';
const { env } = process;
const MAX_DEBUG_SNIPPET_LENGTH = 1000;
const DEFAULT_SAMPLE_RATE = 0.1;

let config;
let userConfig;

const configBuilder = exports;

configBuilder.getConfig = function getConfig() {
  if (!config) {
    throw Error('Call buildConfig before calling getConfig');
  }

  return config;
};

function defaultWorkersCount() {
  return os.cpus().length - 1 || 1;
}

const defaultConfig = {
  // Use env port if we run on Heroku
  port: env.RENDERER_PORT || DEFAULT_PORT,

  // Show only important messages by default, https://github.com/winstonjs/
  // winston#logging-levels:
  logLevel: env.RENDERER_LOG_LEVEL || DEFAULT_LOG_LEVEL,

  // Use directory DEFAULT_TMP_DIR if none provided
  bundlePath: env.RENDERER_BUNDLE_PATH || DEFAULT_TMP_DIR,

  // supportModules should be set to true to allow the server-bundle code to see require, exports, etc.
  // false is like the ExecJS behavior
  supportModules: env.RENDERER_SUPPORT_MODULES || null,

  // Workers count defaults to number of CPUs minus 1
  workersCount:
    (env.RENDERER_WORKERS_COUNT && parseInt(env.RENDERER_WORKERS_COUNT, 10)) || defaultWorkersCount(),

  // No default for password, means no auth
  password: env.RENDERER_PASSWORD,

  // Next 2 params, allWorkersRestartInterval and delayBetweenIndividualWorkerRestarts must both
  // be set if you wish to have automatic worker restarting, say to clear memory leaks.
  // time in minutes between restarting all workers
  allWorkersRestartInterval:
    env.RENDERER_ALL_WORKERS_RESTART_INTERVAL && parseInt(env.RENDERER_ALL_WORKERS_RESTART_INTERVAL, 10),

  // time in minutes between each worker restarting when restarting all workers
  delayBetweenIndividualWorkerRestarts:
    env.RENDERER_DELAY_BETWEEN_INDIVIDUAL_WORKER_RESTARTS &&
    parseInt(env.RENDERER_DELAY_BETWEEN_INDIVIDUAL_WORKER_RESTARTS, 10),

  maxDebugSnippetLength: MAX_DEBUG_SNIPPET_LENGTH,

  honeybadgerApiKey: env.HONEYBADGER_API_KEY || null,

  sentryDsn: env.SENTRY_DSN || null,

  sentryTracing: env.SENTRY_TRACING || null,

  sentryTracesSampleRate: env.SENTRY_TRACES_SAMPLE_RATE || DEFAULT_SAMPLE_RATE,

  // // default to true if empty // otherwise it is set to false
  includeTimerPolyfills: env.INCLUDE_TIMER_POLYFILLS === 'true' || !env.INCLUDE_TIMER_POLYFILLS,
};

function envValuesUsed() {
  return {
    RENDERER_PORT: !userConfig.port && env.RENDERER_PORT,
    RENDERER_LOG_LEVEL: !userConfig.logLevel && env.RENDERER_LOG_LEVEL,
    RENDERER_BUNDLE_PATH: !userConfig.bundlePath && env.RENDERER_BUNDLE_PATH,
    RENDERER_WORKERS_COUNT: !userConfig.workersCount && env.RENDERER_WORKERS_COUNT,
    RENDERER_PASSWORD: !userConfig.password && env.RENDERER_PASSWORD && '<MASKED',
    RENDERER_SUPPORT_MODULES: !userConfig.supportModules && env.RENDERER_SUPPORT_MODULES,
    RENDERER_ALL_WORKERS_RESTART_INTERVAL:
      !userConfig.allWorkersRestartInterval && env.RENDERER_ALL_WORKERS_RESTART_INTERVAL,
    RENDERER_DELAY_BETWEEN_INDIVIDUAL_WORKER_RESTARTS:
      !userConfig.delayBetweenIndividualWorkerRestarts &&
      env.RENDERER_DELAY_BETWEEN_INDIVIDUAL_WORKER_RESTARTS,
  };
}

function sanitizedSettings(aConfig, defaultValue) {
  return Object.assign({}, aConfig, {
    password: (aConfig.password && '<MASKED>') || defaultValue,
    allWorkersRestartInterval: aConfig.allWorkersRestartInterval || defaultValue,
    delayBetweenIndividualWorkerRestarts: aConfig.delayBetweenIndividualWorkerRestarts || defaultValue,
  });
}

configBuilder.logSanitizedConfig = function logSanitizedConfig() {
  log.info(`Node Renderer v${packageJson.version}, protocol v${packageJson.protocolVersion}`);
  log.info('NOTE: renderer settings names do not have prefix "RENDERER_"');
  log.info('Default values for settings:\n%O', defaultConfig);
  log.info('ENV values used for settings (use "RENDERER_" prefix):\n%O', envValuesUsed());
  log.info(
    'Customized values for settings from config object (overides ENV):\n%O',
    sanitizedSettings(configBuilder.getConfig()),
  );
  log.info('Final renderer settings used:\n%O', sanitizedSettings(config, '<NOT PROVIDED>'));
};

/**
 * Lazily create the config
 * @param providedUserConfig
 * @returns {*}
 */
configBuilder.buildConfig = function buildConfig(providedUserConfig) {
  userConfig = providedUserConfig || {};
  config = Object.assign({}, defaultConfig, userConfig);

  config.supportModules = truthy(config.supportModules);
  config.sentryTracing = truthy(config.sentryTracing);

  let currentArg;

  process.argv.forEach((val) => {
    if (val[0] === '-') {
      currentArg = val.slice(1);
      return;
    }

    if (currentArg === 'p') {
      config.port = val;
    }
  });

  if (config.honeybadgerApiKey) {
    errorReporter.addHoneybadgerApiKey(config.honeybadgerApiKey);
  }

  if (config.sentryDsn) {
    if (config.sentryTracing) {
      let sampleRate = parseFloat(config.sentryTracesSampleRate);

      if (Number.isNaN(sampleRate)) {
        log.warn(
          `SENTRY_TRACES_SAMPLE_RATE "${config.sentryTracesSampleRate}" is not a number. Using default of ${DEFAULT_SAMPLE_RATE}`,
        );
        sampleRate = DEFAULT_SAMPLE_RATE;
      }

      errorReporter.addSentryDsn(config.sentryDsn, {
        tracing: config.sentryTracing,
        tracesSampleRate: sampleRate,
      });

      tracing.setSentry(Sentry);
    } else {
      errorReporter.addSentryDsn(config.sentryDsn);
    }
  }

  configureLogger(log, config.logLevel);
  return config;
};
