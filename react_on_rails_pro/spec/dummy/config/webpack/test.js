process.env.NODE_ENV = process.env.NODE_ENV || 'test';

const webpackConfig = require('./ServerClientOrBoth');

const testOnly = () => {
  // place any code here that is for test only
};

module.exports = webpackConfig(testOnly);
