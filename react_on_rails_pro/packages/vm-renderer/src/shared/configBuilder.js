/**
 * Reads CLI arguments and build the config.
 * @module worker/configBuilder
 */

let config;

const DEFAULT_PORT = 3800;
const DEFAULT_LOG_LEVEL = 'info';

const defaultConfig = {
  bundlePath: undefined,           // No defaults for bundlePath
  port: process.env.PORT || DEFAULT_PORT,  // Use env port if we run on Heroku

  // Show only important messages by default, https://github.com/winstonjs/winston#logging-levels:
  logLevel: process.env.LOG_LEVEL || DEFAULT_LOG_LEVEL,

  workersCount: undefined,         // Let master detect workers count automaticaly
  password: undefined,             // No default for password, means no auth

  // Next 2 params, allWorkersRestartInterval and delayBetweenIndividualWorkerRestarts must both
  // be set if you wish to have automatic worker restarting, say to clear memory leaks.
  // time in minutes between restarting all workers
  allWorkersRestartInterval: undefined,

  // time in minutes between each worker restarting when restarting all workers
  delayBetweenIndividualWorkerRestarts: undefined,
};

exports.buildConfig = function buildConfig(userConfig) {
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
};

exports.getConfig = function getConfig() {
  return config;
};
