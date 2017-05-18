/**
 * Reads CLI arguments and build the config.
 * @module worker/configBuilder
 */

let config;

const defaultConfig = {
  bundlePath: undefined,           // No defaults for bundlePath
  port: process.env.PORT || 3700,  // Use env port if we run on Heroku

  // Show only important messages by default, https://github.com/winstonjs/winston#logging-levels:
  logLevel: 'info',

  workersCount: undefined,         // Let master detect workers count automaticaly
  password: undefined,             // No default for password, means no auth
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
