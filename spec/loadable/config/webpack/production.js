process.env.NODE_ENV = process.env.NODE_ENV || 'production';

// Below code should get refactored but the current way that rails/webpacker v5
// does the globals, it's tricky
const webpackConfig = require('./webpackConfig');

const productionEnvOnly = (_clientWebpackConfig, _serverWebpackConfig) => {
  // place any code here that is for production only
};

module.exports = webpackConfig(productionEnvOnly);
