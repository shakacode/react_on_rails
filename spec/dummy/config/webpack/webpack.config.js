const { env } = require('shakapacker');
const { existsSync } = require('fs');
const { resolve } = require('path');

const envSpecificConfig = () => {
  const path = resolve(__dirname, `${env.nodeEnv}.js`);
  if (existsSync(path)) {
    console.log(`Loading ENV specific webpack configuration file ${path}`);
    return require(path);
  } else {
    throw new Error(
      `Invalid NODE_ENV = ${env.nodeEnv}. Please use one of the following 'test', 'development' or 'production'.`,
    );
  }
};

module.exports = envSpecificConfig();
