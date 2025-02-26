const { env, generateWebpackConfig } = require('shakapacker');

const { existsSync } = require('fs');
const { resolve } = require('path');

const envSpecificConfig = () => {
  const path = resolve(__dirname, `${env.nodeEnv}.js`);
  if (existsSync(path)) {
    console.log(`Loading ENV specific webpack configuration file ${path}`);
    // eslint-disable-next-line import/no-dynamic-require, global-require
    return require(path);
  }
  return generateWebpackConfig();
};

module.exports = envSpecificConfig();
