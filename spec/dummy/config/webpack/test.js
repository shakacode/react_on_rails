process.env.NODE_ENV = process.env.NODE_ENV || 'production';

const webpackConfig = require('./webpackConfig');

const testOnly = (_clientWebpackConfig, _serverWebpackConfig) => {
  // place any code here that is for test only
};

module.exports = webpackConfig(testOnly);
