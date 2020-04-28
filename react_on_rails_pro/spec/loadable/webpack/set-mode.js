const _ = require('lodash/fp');

function setMode(builderConfig, webpackConfig) {
  const mode = builderConfig.developerAids ? 'development' : 'production';
  return _.set('mode', mode, webpackConfig);
}

module.exports = _.curry(setMode);
