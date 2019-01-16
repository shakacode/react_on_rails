/**
 * Reads CLI arguments and build the config.
 * @module worker/configBuilder
 */
import fs from 'fs';
import os from 'os';

import log, { configureLogger } from './log';
import errorReporter from './errorReporter';
import packageJson from './packageJson';

const DEFAULT_TMP_DIR = '/tmp/react-on-rails-pro-vm-renderer-bundles';
const DEFAULT_PORT = 3800;
const DEFAULT_LOG_LEVEL = 'info';
const { env } = process;
const MAX_DEBUG_SNIPPET_LENGTH = 1000;

let config;
let userConfig;

export function getConfig() {
  if (!config) {
    throw Error('Call buildConfig before calling getConfig');
  }

  return config;
}

function getTmpDir() {
  if (!fs.existsSync(DEFAULT_TMP_DIR)) {
    fs.mkdirSync(DEFAULT_TMP_DIR);
  }
  return DEFAULT_TMP_DIR;
}

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
  bundlePath: env.RENDERER_BUNDLE_PATH || getTmpDir(),

  // Workers count defaults to number of CPUs minus 1
  workersCount: env.RENDERER_WORKERS_COUNT || defaultWorkersCount(),

  // No default for password, means no auth
  password: env.RENDERER_PASSWORD,

  // Next 2 params, allWorkersRestartInterval and delayBetweenIndividualWorkerRestarts must both
  // be set if you wish to have automatic worker restarting, say to clear memory leaks.
  // time in minutes between restarting all workers
  allWorkersRestartInterval: env.RENDERER_ALL_WORKERS_RESTART_INTERVAL,

  // time in minutes between each worker restarting when restarting all workers
  delayBetweenIndividualWorkerRestarts: env.RENDERER_DELAY_BETWEEN_INDIVIDUAL_WORKER_RESTARTS,

  maxDebugSnippetLength: MAX_DEBUG_SNIPPET_LENGTH,

  honeybadgerApiKey: env.HONEYBADGER_API_KEY || null,

  sentryDsn: env.SENTRY_DSN || null,
};

function envValuesUsed() {
  return {
    RENDERER_PORT: !userConfig.port && env.RENDERER_PORT,
    RENDERER_LOG_LEVEL: !userConfig.logLevel && env.RENDERER_LOG_LEVEL,
    RENDERER_BUNDLE_PATH: !userConfig.bundlePath && env.RENDERER_BUNDLE_PATH,
    RENDERER_WORKERS_COUNT: !userConfig.workersCount && env.RENDERER_WORKERS_COUNT,
    RENDERER_PASSWORD: !userConfig.password && (env.RENDERER_PASSWORD && '<MASKED'),
    RENDERER_ALL_WORKERS_RESTART_INTERVAL: !userConfig.allWorkersRestartInterval &&
      env.RENDERER_ALL_WORKERS_RESTART_INTERVAL,
    RENDERER_DELAY_BETWEEN_INDIVIDUAL_WORKER_RESTARTS:
      !userConfig.delayBetweenIndividualWorkerRestarts &&
      env.RENDERER_DELAY_BETWEEN_INDIVIDUAL_WORKER_RESTARTS,
  };
}

function sanitizedSettings(aConfig, defaultValue) {
  return Object.assign({}, aConfig, {
    password: (aConfig.password && '<MASKED>') || defaultValue,
    allWorkersRestartInterval: aConfig.allWorkersRestartInterval || defaultValue,
    delayBetweenIndividualWorkerRestarts: aConfig.delayBetweenIndividualWorkerRestarts
      || defaultValue,
  });
}

export function logSanitizedConfig() {
  log.info(`VM Renderer v${packageJson.version}, protocol v${packageJson.protocolVersion}`);
  log.info('NOTE: renderer settings names do not have prefix "RENDERER_"');
  log.info('Default values for settings:\n%O', defaultConfig);
  log.info('Customized values for settings from config object:\n%O', sanitizedSettings(getConfig()));
  log.info('ENV values used for settings (use "RENDERER_" prefix):\n%O', envValuesUsed());
  log.info('Final renderer settings used:\n%O', sanitizedSettings(config, '<NOT PROVIDED>'));
}

/**
 * Lazily create the config
 * @param providedUserConfig
 * @returns {*}
 */
export function buildConfig(providedUserConfig) {
  userConfig = providedUserConfig || {};
  config = Object.assign({}, defaultConfig, userConfig);

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
    errorReporter.addSentryDsn(config.sentryDsn);
  }

  configureLogger(log, config.logLevel);
  return config;
}
