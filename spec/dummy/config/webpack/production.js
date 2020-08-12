process.env.NODE_ENV = process.env.NODE_ENV || 'production';

const webpackConfig = require('./webpackConfig');

const productionOnly = () => {
  // place any code here that is for production only
};

module.exports = webpackConfig(productionOnly);
