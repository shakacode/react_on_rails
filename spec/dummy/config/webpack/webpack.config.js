const { env, generateWebpackConfig, webpackConfig: v6WebpackConfig, merge } = require('shakapacker');

const generateWebpackConfigAlias = generateWebpackConfig ? generateWebpackConfig : () => undefined;

const { existsSync } = require('fs');
const { resolve } = require('path');

const envSpecificConfig = () => {
  const path = resolve(__dirname, `${env.nodeEnv}.js`);
  if (existsSync(path)) {
    console.log(`Loading ENV specific webpack configuration file ${path}`);
    return require(path);
  } else {
    return v6WebpackConfig ? v6WebpackConfig : generateWebpackConfigAlias();
  }
};

module.exports = envSpecificConfig();
