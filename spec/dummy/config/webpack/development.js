process.env.NODE_ENV = process.env.NODE_ENV || 'development';

const webpackConfig = require('./webpackConfig');

const developmentOnly = () => {
  // place any code here that is for development only
};

module.exports = webpackConfig(developmentOnly);
