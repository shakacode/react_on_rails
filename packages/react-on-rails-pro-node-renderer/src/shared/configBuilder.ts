/**
 * Reads CLI arguments and build the config.
 *
 * @module worker/configBuilder
 */
import os from 'os';
import path from 'path';
import fs from 'fs';
import * as http2 from 'node:http2';
import { FastifyServerOptions } from 'fastify';
import { LevelWithSilent } from 'pino';
import log from './log.js';
import packageJson from './packageJson.js';
import truthy from './truthy.js';

// usually remote renderers are on staging or production, so, use production folder always
const DEFAULT_PORT = 3800;
const DEFAULT_LOG_LEVEL = 'info';
const { env } = process;
const MAX_DEBUG_SNIPPET_LENGTH = 1000;
const NODE_ENV = env.NODE_ENV || 'production';

/* Update ./docs/node-renderer/js-configuration.md when something here changes */
// Node renderer configuration
export interface Config {
  // The port the renderer should listen to. On Heroku you may want to use `process.env.PORT`:
  // https://devcenter.heroku.com/articles/dyno-startup-behavior#port-binding-of-web-dynos
  // Similarly on ControlPlane: https://docs.controlplane.com/reference/workload/containers#port-variable
  port: number;
  // The renderer log level
  logLevel: LevelWithSilent;
  // The HTTP server log level
  logHttpLevel: LevelWithSilent;
  // Additional options to pass to the Fastify server factory.
  // See https://fastify.dev/docs/latest/Reference/Server/#factory.
  fastifyServerOptions: FastifyServerOptions<http2.Http2Server>;
  // Path to a cache directory where uploaded server bundle files will be stored.
  // This is distinct from Shakapacker's public asset directory.
  serverBundleCachePath: string;
  // @deprecated Use serverBundleCachePath instead. This will be removed in a future version.
  bundlePath?: string;
  // If set to true, `supportModules` enables the server-bundle code to call a default set of NodeJS
  // global objects and functions that get added to the VM context:
  // `{ Buffer, TextDecoder, TextEncoder, URLSearchParams, ReadableStream, process, setTimeout, setInterval, setImmediate, clearTimeout, clearInterval, clearImmediate, queueMicrotask }`.
  // This option is required to equal `true` if you want to use loadable components.
  // Setting this value to false causes the NodeRenderer to behave like ExecJS.
  supportModules: boolean;
  // additionalContext enables you to specify additional NodeJS objects (usually from
  // https://nodejs.org/api/globals.html) to add to the VM context in addition to our supportModules defaults.
  // Object shorthand notation may be used, but is not required.
  // Example: { URL, URLSearchParams, Crypto }
  additionalContext: Record<string, unknown> | null;
  // Number of workers that will be forked to serve rendering requests.
  workersCount: number;
  // The password expected to receive from the **Rails client** to authenticate rendering requests.
  // If no password is set, no authentication will be required.
  password: string | undefined;
  // Next 2 params, allWorkersRestartInterval and delayBetweenIndividualWorkerRestarts must both
  // be set if you wish to have automatic worker restarting, say to clear memory leaks.
  // Time in minutes between restarting all workers
  allWorkersRestartInterval: number | undefined;
  // Time in minutes between each worker restarting when restarting all workers
  delayBetweenIndividualWorkerRestarts: number | undefined;
  // Time in seconds to wait for worker to restart before killing it
  // Set it to 0 or undefined to never kill the worker
  gracefulWorkerRestartTimeout: number | undefined;
  // If the rendering request is longer than this, it will be truncated in exception and logging messages
  maxDebugSnippetLength: number;
  // @deprecated See https://www.shakacode.com/react-on-rails-pro/docs/node-renderer/error-reporting-and-tracing.
  honeybadgerApiKey?: string | null;
  // @deprecated See https://www.shakacode.com/react-on-rails-pro/docs/node-renderer/error-reporting-and-tracing.
  sentryDsn?: string | null;
  // @deprecated See https://www.shakacode.com/react-on-rails-pro/docs/node-renderer/error-reporting-and-tracing.
  sentryTracing?: boolean;
  // @deprecated See https://www.shakacode.com/react-on-rails-pro/docs/node-renderer/error-reporting-and-tracing.
  sentryTracesSampleRate?: string | number;
  // If true, `{set/clear}{Timeout/Interval/Immediate}` and `queueMicrotask` are stubbed out to do nothing.
  stubTimers: boolean;
  // @deprecated Use stubTimers instead.
  includeTimerPolyfills?: boolean;
  // If set to true, this option enables the replay of console logs from asynchronous server operations.
  // If set to false, only logs that occur on the server prior to any awaited asynchronous operations will be replayed.
  // The default value is true in development, otherwise it is set to false.
  replayServerAsyncOperationLogs: boolean;
  // Maximum number of VM contexts to keep in memory. Defaults to 2 since typically only two contexts
  // are needed - one for the server bundle and one for React Server Components (RSC) if enabled.
  // Older contexts are removed when this limit is reached.
  maxVMPoolSize: number;
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
function defaultServerBundleCachePath() {
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

  fastifyServerOptions: {},

  serverBundleCachePath:
    env.RENDERER_SERVER_BUNDLE_CACHE_PATH || env.RENDERER_BUNDLE_PATH || defaultServerBundleCachePath(),

  supportModules: truthy(env.RENDERER_SUPPORT_MODULES),

  additionalContext: null,

  // Workers count defaults to number of CPUs minus 1
  workersCount: env.RENDERER_WORKERS_COUNT ? parseInt(env.RENDERER_WORKERS_COUNT, 10) : defaultWorkersCount(),

  // No default for password, means no auth
  password: env.RENDERER_PASSWORD,

  allWorkersRestartInterval: env.RENDERER_ALL_WORKERS_RESTART_INTERVAL
    ? parseInt(env.RENDERER_ALL_WORKERS_RESTART_INTERVAL, 10)
    : undefined,

  delayBetweenIndividualWorkerRestarts: env.RENDERER_DELAY_BETWEEN_INDIVIDUAL_WORKER_RESTARTS
    ? parseInt(env.RENDERER_DELAY_BETWEEN_INDIVIDUAL_WORKER_RESTARTS, 10)
    : undefined,

  gracefulWorkerRestartTimeout: env.GRACEFUL_WORKER_RESTART_TIMEOUT
    ? parseInt(env.GRACEFUL_WORKER_RESTART_TIMEOUT, 10)
    : undefined,

  maxDebugSnippetLength: MAX_DEBUG_SNIPPET_LENGTH,

  // default to true if empty, otherwise it is set to false
  stubTimers: env.RENDERER_STUB_TIMERS === 'true' || !env.RENDERER_STUB_TIMERS,

  // default to true in development, otherwise it is set to false
  replayServerAsyncOperationLogs: truthy(
    env.REPLAY_SERVER_ASYNC_OPERATION_LOGS ?? NODE_ENV === 'development',
  ),

  // Maximum number of VM contexts to keep in memory. Defaults to 2 since typically only two contexts
  // are needed - one for the server bundle and one for React Server Components (RSC) if enabled.
  maxVMPoolSize: (env.MAX_VM_POOL_SIZE && parseInt(env.MAX_VM_POOL_SIZE, 10)) || 2,
};

function envValuesUsed() {
  return {
    RENDERER_PORT: !userConfig.port && env.RENDERER_PORT,
    RENDERER_LOG_LEVEL: !userConfig.logLevel && env.RENDERER_LOG_LEVEL,
    RENDERER_LOG_HTTP_LEVEL: !userConfig.logHttpLevel && env.RENDERER_LOG_HTTP_LEVEL,
    RENDERER_SERVER_BUNDLE_CACHE_PATH:
      !userConfig.serverBundleCachePath && env.RENDERER_SERVER_BUNDLE_CACHE_PATH,
    RENDERER_BUNDLE_PATH:
      !userConfig.serverBundleCachePath && !userConfig.bundlePath && env.RENDERER_BUNDLE_PATH,
    RENDERER_WORKERS_COUNT: !userConfig.workersCount && env.RENDERER_WORKERS_COUNT,
    RENDERER_PASSWORD: !userConfig.password && env.RENDERER_PASSWORD && '<MASKED>',
    RENDERER_SUPPORT_MODULES: !('supportModules' in userConfig) && env.RENDERER_SUPPORT_MODULES,
    RENDERER_STUB_TIMERS: !('stubTimers' in userConfig) && env.RENDERER_STUB_TIMERS,
    RENDERER_ALL_WORKERS_RESTART_INTERVAL:
      !userConfig.allWorkersRestartInterval && env.RENDERER_ALL_WORKERS_RESTART_INTERVAL,
    RENDERER_DELAY_BETWEEN_INDIVIDUAL_WORKER_RESTARTS:
      !userConfig.delayBetweenIndividualWorkerRestarts &&
      env.RENDERER_DELAY_BETWEEN_INDIVIDUAL_WORKER_RESTARTS,
    GRACEFUL_WORKER_RESTART_TIMEOUT:
      !userConfig.gracefulWorkerRestartTimeout && env.GRACEFUL_WORKER_RESTART_TIMEOUT,
    INCLUDE_TIMER_POLYFILLS: !('includeTimerPolyfills' in userConfig) && env.INCLUDE_TIMER_POLYFILLS,
    REPLAY_SERVER_ASYNC_OPERATION_LOGS:
      !userConfig.replayServerAsyncOperationLogs && env.REPLAY_SERVER_ASYNC_OPERATION_LOGS,
    MAX_VM_POOL_SIZE: !userConfig.maxVMPoolSize && env.MAX_VM_POOL_SIZE,
  };
}

function sanitizedSettings(aConfig: Partial<Config> | undefined, defaultValue?: string) {
  return aConfig && Object.keys(aConfig).length > 0
    ? {
        ...aConfig,
        password: aConfig.password != null ? '<MASKED>' : defaultValue,
        allWorkersRestartInterval: aConfig.allWorkersRestartInterval || defaultValue,
        delayBetweenIndividualWorkerRestarts: aConfig.delayBetweenIndividualWorkerRestarts || defaultValue,
        gracefulWorkerRestartTimeout: aConfig.gracefulWorkerRestartTimeout || defaultValue,
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

  // Handle bundlePath deprecation
  if ('bundlePath' in userConfig) {
    log.warn(
      'bundlePath is deprecated and will be removed in a future version. ' +
        'Use serverBundleCachePath instead. This path stores uploaded server bundles for the node renderer, ' +
        'not client-side webpack assets from Shakapacker.',
    );
    // If serverBundleCachePath is not set, use bundlePath as fallback
    if (
      userConfig.bundlePath &&
      (!config.serverBundleCachePath || config.serverBundleCachePath === defaultConfig.serverBundleCachePath)
    ) {
      config.serverBundleCachePath = userConfig.bundlePath;
    }
  }
  if (env.RENDERER_BUNDLE_PATH && !env.RENDERER_SERVER_BUNDLE_CACHE_PATH) {
    log.warn(
      'RENDERER_BUNDLE_PATH environment variable is deprecated and will be removed in a future version. ' +
        'Use RENDERER_SERVER_BUNDLE_CACHE_PATH instead.',
    );
  }

  config.supportModules = truthy(config.supportModules);

  if (config.maxVMPoolSize <= 0 || !Number.isInteger(config.maxVMPoolSize)) {
    throw new Error('maxVMPoolSize must be a positive integer');
  }

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
      'honeybadgerApiKey, sentryDsn, sentryTracing, and sentryTracesSampleRate are not used since RoRP 4.0. ' +
        'See https://www.shakacode.com/react-on-rails-pro/docs/node-renderer/error-reporting-and-tracing.',
    );
    process.exit(1);
  }

  if (env.INCLUDE_TIMER_POLYFILLS) {
    log.error('INCLUDE_TIMER_POLYFILLS environment variable is renamed to RENDERER_STUB_TIMERS in RoRP 4.0');
    process.exit(1);
  }
  if ('includeTimerPolyfills' in config) {
    log.error('includeTimerPolyfills is renamed to stubTimers in RoRP 4.0');
    process.exit(1);
  }

  log.level = config.logLevel;
  return config;
}
