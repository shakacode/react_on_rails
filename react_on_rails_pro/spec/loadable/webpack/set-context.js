const _ = require('lodash/fp');
const path = require('path');

function setContext(_builderConfig, webpackConfig) {
  const context = path.resolve(__dirname, '..');
  return _.set('context', context, webpackConfig);
}

module.exports = _.curry(setContext);
