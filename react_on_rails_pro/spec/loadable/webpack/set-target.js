const _ = require('lodash/fp');

function setTarget(builderConfig, webpackConfig) {
  const target = builderConfig.serverRendering ? 'node' : 'web';
  return _.set('target', target, webpackConfig);
}

module.exports = _.curry(setTarget);
