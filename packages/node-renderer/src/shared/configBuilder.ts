/**
 * Reads CLI arguments and build the config.
 *
 * @module worker/configBuilder
 */
import os from 'os';
import path from 'path';
import fs from 'fs';
import { LevelWithSilent } from 'pino';
import log from './log';
import packageJson from './packageJson';
import truthy from './truthy';

// usually remote renderers are on staging or production, so, use production folder always
const DEFAULT_PORT = 3800;
const DEFAULT_LOG_LEVEL = 'info';
const { env } = process;
const MAX_DEBUG_SNIPPET_LENGTH = 1000;
const NODE_ENV = env.NODE_ENV || 'production';

export interface Config {
  port: number;
  logLevel: LevelWithSilent;
  logHttpLevel: LevelWithSilent;
  bundlePath: string;
  // If set to true, `supportModules` enables the server-bundle code to call a default set of NodeJS
  // global objects and functions that get added to the VM context:
  // `{ Buffer, process, setTimeout, setInterval, clearTimeout, clearInterval, setImmediate, clearImmediate, queueMicrotask }`.
  // This option is required to equal `true` if you want to use loadable components.
  // Setting this value to false causes the NodeRenderer to behave like ExecJS.
  supportModules: boolean;
  // additionalContext enables you to specify additional NodeJS objects (usually from
  // https://nodejs.org/api/globals.html) to add to the VM context in addition to our supportModules defaults.
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
  // @deprecated See https://www.shakacode.com/react-on-rails-pro/docs/node-renderer/error-reporting-and-tracing.
  honeybadgerApiKey?: string | null;
  // @deprecated See https://www.shakacode.com/react-on-rails-pro/docs/node-renderer/error-reporting-and-tracing.
  sentryDsn?: string | null;
  // @deprecated See https://www.shakacode.com/react-on-rails-pro/docs/node-renderer/error-reporting-and-tracing.
  sentryTracing?: boolean;
  // @deprecated See https://www.shakacode.com/react-on-rails-pro/docs/node-renderer/error-reporting-and-tracing.
  sentryTracesSampleRate?: string | number;
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

function logLevel(level: string): LevelWithSilent {
  switch (level) {
    case 'fatal':
    case 'error':
    case 'warn':
    case 'info':
    case 'debug':
    case 'trace':
    case 'silent':
      return level;
    default:
      log.error(`Unexpected log level: ${level}`);
      return DEFAULT_LOG_LEVEL;
  }
}

const defaultConfig: Config = {
  // Use env port if we run on Heroku
  port: Number(env.RENDERER_PORT) || DEFAULT_PORT,

  // Show only important messages by default
  logLevel: logLevel(env.RENDERER_LOG_LEVEL || DEFAULT_LOG_LEVEL),

  // Log only errors from Fastify by default
  logHttpLevel: logLevel(env.RENDERER_LOG_HTTP_LEVEL || 'error'),

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
    RENDERER_LOG_HTTP_LEVEL: !userConfig.logHttpLevel && env.RENDERER_LOG_HTTP_LEVEL,
    RENDERER_BUNDLE_PATH: !userConfig.bundlePath && env.RENDERER_BUNDLE_PATH,
    RENDERER_WORKERS_COUNT: !userConfig.workersCount && env.RENDERER_WORKERS_COUNT,
    RENDERER_PASSWORD: !userConfig.password && env.RENDERER_PASSWORD && '<MASKED>',
    RENDERER_SUPPORT_MODULES: !userConfig.supportModules && env.RENDERER_SUPPORT_MODULES,
    RENDERER_ALL_WORKERS_RESTART_INTERVAL:
      !userConfig.allWorkersRestartInterval && env.RENDERER_ALL_WORKERS_RESTART_INTERVAL,
    RENDERER_DELAY_BETWEEN_INDIVIDUAL_WORKER_RESTARTS:
      !userConfig.delayBetweenIndividualWorkerRestarts &&
      env.RENDERER_DELAY_BETWEEN_INDIVIDUAL_WORKER_RESTARTS,
    INCLUDE_TIMER_POLYFILLS: !userConfig.includeTimerPolyfills && env.INCLUDE_TIMER_POLYFILLS,
    REPLAY_SERVER_ASYNC_OPERATION_LOGS:
      !userConfig.replayServerAsyncOperationLogs && env.REPLAY_SERVER_ASYNC_OPERATION_LOGS,
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
  log.info({
    'Node Renderer version': packageJson.version,
    'Protocol version': packageJson.protocolVersion,
    'Default settings': defaultConfig,
    'ENV values used for settings (use "RENDERER_" prefix)': envValuesUsed(),
    'Customized values for settings from config object (overrides ENV)': sanitizedSettings(userConfig),
    'Final renderer settings': sanitizedSettings(config, '<NOT PROVIDED>'),
  });
}

/**
 * Lazily create the config
 */
export function buildConfig(providedUserConfig?: Partial<Config>): Config {
  userConfig = providedUserConfig || {};
  config = { ...defaultConfig, ...userConfig };

  config.supportModules = truthy(config.supportModules);

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

  if (
    'honeybadgerApiKey' in config ||
    'sentryDsn' in config ||
    'sentryTracing' in config ||
    'sentryTracesSampleRate' in config
  ) {
    log.error(
      'honeybadgerApiKey, sentryDsn, sentryTracing, and sentryTracesSampleRate are not used since RORP 4.0. ' +
        'See https://www.shakacode.com/react-on-rails-pro/docs/node-renderer/error-reporting-and-tracing.',
    );
  }

  log.level = config.logLevel;
  return config;
}
