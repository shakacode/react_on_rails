const _ = require('lodash/fp');

const entries = {
  'foo-bundle': './client/app/bundles/foo/startup/foo-bundle',
};

function setEntry(builderConfig, webpackConfig) {
  if (builderConfig.serverRendering) {
    return _.set(
      'entry',
      {
        'server-bundle': './client/app/bundles/server/server-bundle',
      },
      webpackConfig,
    );
  }

  return _.set('entry', entries, webpackConfig);
}

module.exports = _.curry(setEntry);
