// The source code including full typescript support is available at: 
// https://github.com/shakacode/react_on_rails_demo_ssr_hmr/blob/master/config/webpack/production.js

const webpackConfig = require('./webpackConfig');

const productionEnvOnly = (_clientWebpackConfig, _serverWebpackConfig) => {
  // place any code here that is for production only
};

module.exports = webpackConfig(productionEnvOnly);
