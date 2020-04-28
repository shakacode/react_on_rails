const _ = require('lodash/fp');

function setDevtool(builderConfig, webpackConfig) {
  return _.set(
    'devtool',
    builderConfig.sourceMaps === 'plugin' ? false : builderConfig.sourceMaps,
    webpackConfig,
  );
}

module.exports = _.curry(setDevtool);
