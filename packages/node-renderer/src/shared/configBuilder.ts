/**
 * Reads CLI arguments and build the config.
 *
 * @module worker/configBuilder
 */
import os from 'os';
import path from 'path';
import fs from 'fs';
import requireOptional from './requireOptional';
import log, { configureLogger } from './log';
import errorReporter from './errorReporter';
import tracing from './tracing';
import packageJson from './packageJson';
import truthy from './truthy';

const Sentry = requireOptional('@sentry/node') as typeof import('@sentry/node') | null;

// usually remote renderers are on staging or production, so, use production folder always
const DEFAULT_PORT = 3800;
const DEFAULT_LOG_LEVEL = 'info';
const { env } = process;
const MAX_DEBUG_SNIPPET_LENGTH = 1000;
const DEFAULT_SAMPLE_RATE = 0.1;
const NODE_ENV = env.NODE_ENV || 'production';

export interface Config {
  port: number;
  // One of https://github.com/winstonjs/winston#logging-levels
  logLevel: string;
  bundlePath: string;
  // If set to true, `supportModules` enables the server-bundle code to call a default set of NodeJS modules
  // that get added to the VM context: `{ Buffer, process, setTimeout, setInterval, clearTimeout, clearInterval }`.
  // This option is required to equal `true` if you want to use loadable components.
  // Setting this value to false causes the NodeRenderer to behave like ExecJS.
  supportModules: boolean;
  // additionalContext enables you to specify additional NodeJS modules to add to the VM context in
  // addition to our supportModules defaults.
  // Object shorthand notation may be used, but is not required.
  // Example: { URL, URLSearchParams, Crypto }
  additionalContext: Record<string, unknown> | null;
  workersCount: number;
  password: string | undefined;
  // Next 2 params, allWorkersRestartInterval and delayBetweenIndividualWorkerRestarts must both
  // be set if you wish to have automatic worker restarting, say to clear memory leaks.
  // time in minutes between restarting all workers
  allWorkersRestartInterval: number | undefined;
  // time in minutes between each worker restarting when restarting all workers
  delayBetweenIndividualWorkerRestarts: number | undefined;
  maxDebugSnippetLength: number;
  honeybadgerApiKey: string | null;
  sentryDsn: string | null;
  sentryTracing: boolean;
  sentryTracesSampleRate: string | number;
  includeTimerPolyfills: boolean;
  // If set to true, this option enables the replay of console logs from asynchronous server operations.
  // If set to false, only logs that occur on the server prior to any awaited asynchronous operations will be replayed.
  // The default value is true in development, otherwise it is set to false.
  replayServerAsyncOperationLogs: boolean;
}

let config: Config | undefined;
let userConfig: Partial<Config> = {};

export function getConfig() {
  if (!config) {
    throw Error('Call buildConfig before calling getConfig');
  }

  return config;
}

function defaultWorkersCount() {
  // Create a worker for each CPU except one that is used for master process
  return os.cpus().length - 1 || 1;
}

// Find the .node-renderer-bundles folder if it exists, otherwise use /tmp
function defaultBundlePath() {
  let currentDir = process.cwd();
  const maxDepth = 10;
  for (let i = 0; i < maxDepth; i += 1) {
    const nodeRendererBundlesPath = path.resolve(currentDir, '.node-renderer-bundles');
    if (fs.existsSync(nodeRendererBundlesPath)) {
      return nodeRendererBundlesPath;
    }
    const parentDir = path.dirname(currentDir);
    if (parentDir === currentDir) {
      // We're at the root and didn't find the folder
      break;
    }
    currentDir = parentDir;
  }
  return '/tmp/react-on-rails-pro-node-renderer-bundles';
}

const defaultConfig: Config = {
  // Use env port if we run on Heroku
  port: Number(env.RENDERER_PORT) || DEFAULT_PORT,

  // Show only important messages by default
  logLevel: env.RENDERER_LOG_LEVEL || DEFAULT_LOG_LEVEL,

  bundlePath: env.RENDERER_BUNDLE_PATH || defaultBundlePath(),

  supportModules: truthy(env.RENDERER_SUPPORT_MODULES),

  additionalContext: null,

  // Workers count defaults to number of CPUs minus 1
  workersCount:
    (env.RENDERER_WORKERS_COUNT && parseInt(env.RENDERER_WORKERS_COUNT, 10)) || defaultWorkersCount(),

  // No default for password, means no auth
  password: env.RENDERER_PASSWORD,

  allWorkersRestartInterval: env.RENDERER_ALL_WORKERS_RESTART_INTERVAL
    ? parseInt(env.RENDERER_ALL_WORKERS_RESTART_INTERVAL, 10)
    : undefined,

  delayBetweenIndividualWorkerRestarts: env.RENDERER_DELAY_BETWEEN_INDIVIDUAL_WORKER_RESTARTS
    ? parseInt(env.RENDERER_DELAY_BETWEEN_INDIVIDUAL_WORKER_RESTARTS, 10)
    : undefined,

  maxDebugSnippetLength: MAX_DEBUG_SNIPPET_LENGTH,

  honeybadgerApiKey: env.HONEYBADGER_API_KEY || null,

  sentryDsn: env.SENTRY_DSN || null,

  sentryTracing: truthy(env.SENTRY_TRACING),

  sentryTracesSampleRate: env.SENTRY_TRACES_SAMPLE_RATE || DEFAULT_SAMPLE_RATE,

  // default to true if empty, otherwise it is set to false
  includeTimerPolyfills: env.INCLUDE_TIMER_POLYFILLS === 'true' || !env.INCLUDE_TIMER_POLYFILLS,

  // default to true in development, otherwise it is set to false
  replayServerAsyncOperationLogs: truthy(
    env.REPLAY_SERVER_ASYNC_OPERATION_LOGS ?? NODE_ENV === 'development',
  ),
};

function envValuesUsed() {
  return {
    RENDERER_PORT: !userConfig.port && env.RENDERER_PORT,
    RENDERER_LOG_LEVEL: !userConfig.logLevel && env.RENDERER_LOG_LEVEL,
    RENDERER_BUNDLE_PATH: !userConfig.bundlePath && env.RENDERER_BUNDLE_PATH,
    RENDERER_WORKERS_COUNT: !userConfig.workersCount && env.RENDERER_WORKERS_COUNT,
    RENDERER_PASSWORD: !userConfig.password && env.RENDERER_PASSWORD && '<MASKED>',
    RENDERER_SUPPORT_MODULES: !userConfig.supportModules && env.RENDERER_SUPPORT_MODULES,
    RENDERER_ALL_WORKERS_RESTART_INTERVAL:
      !userConfig.allWorkersRestartInterval && env.RENDERER_ALL_WORKERS_RESTART_INTERVAL,
    RENDERER_DELAY_BETWEEN_INDIVIDUAL_WORKER_RESTARTS:
      !userConfig.delayBetweenIndividualWorkerRestarts &&
      env.RENDERER_DELAY_BETWEEN_INDIVIDUAL_WORKER_RESTARTS,
  };
}

function sanitizedSettings(aConfig: Partial<Config> | undefined, defaultValue?: string) {
  return aConfig && Object.keys(aConfig).length > 0
    ? {
        ...aConfig,
        password: aConfig.password != null ? '<MASKED>' : defaultValue,
        allWorkersRestartInterval: aConfig.allWorkersRestartInterval || defaultValue,
        delayBetweenIndividualWorkerRestarts: aConfig.delayBetweenIndividualWorkerRestarts || defaultValue,
      }
    : {};
}

export function logSanitizedConfig() {
  log.info(`Node Renderer v${packageJson.version}, protocol v${packageJson.protocolVersion}`);
  log.info('NOTE: renderer settings names do not have prefix "RENDERER_"');
  log.info('Default values for settings:\n%O', defaultConfig);
  log.info('ENV values used for settings (use "RENDERER_" prefix):\n%O', envValuesUsed());
  log.info(
    'Customized values for settings from config object (overides ENV):\n%O',
    sanitizedSettings(userConfig),
  );
  log.info('Final renderer settings used:\n%O', sanitizedSettings(config, '<NOT PROVIDED>'));
}

/**
 * Lazily create the config
 */
export function buildConfig(providedUserConfig?: Partial<Config>): Config {
  userConfig = providedUserConfig || {};
  config = { ...defaultConfig, ...userConfig };

  config.supportModules = truthy(config.supportModules);
  config.sentryTracing = truthy(config.sentryTracing);

  let currentArg: string | undefined;

  process.argv.forEach((val) => {
    if (val[0] === '-') {
      currentArg = val.slice(1);
      return;
    }

    if (currentArg === 'p') {
      // eslint-disable-next-line @typescript-eslint/no-non-null-assertion -- config is still guaranteed to be defined here
      config!.port = parseInt(val, 10);
    }
  });

  if (config.honeybadgerApiKey) {
    errorReporter.addHoneybadgerApiKey(config.honeybadgerApiKey);
  }

  if (config.sentryDsn) {
    if (config.sentryTracing) {
      let sampleRate =
        typeof config.sentryTracesSampleRate === 'number'
          ? config.sentryTracesSampleRate
          : parseFloat(config.sentryTracesSampleRate);

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

      if (Sentry) {
        tracing.setSentry(Sentry);
      }
    } else {
      errorReporter.addSentryDsn(config.sentryDsn);
    }
  }

  configureLogger(log, config.logLevel);
  return config;
}
