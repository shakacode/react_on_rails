const _ = require('lodash/fp');

function setExternals(builderConfig, webpackConfig) {
  const externals = webpackConfig.externals ? webpackConfig.externals : [];
  if (builderConfig.serverRendering) {
    if (process.env.HMR === 'true') {
      externals.push('@loadable/component');
    }
  }
  return _.set('externals', externals, webpackConfig);
}

module.exports = _.curry(setExternals);
