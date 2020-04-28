const _ = require('lodash/fp');

function setWatchOptions(_builderConfig, webpackConfig) {
  const watchOptions = {
    ignored: /node_modules/,
  };

  return _.set('watchOptions', watchOptions, webpackConfig);
}

module.exports = _.curry(setWatchOptions);
