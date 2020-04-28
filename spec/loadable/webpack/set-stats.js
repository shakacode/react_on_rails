const _ = require('lodash/fp');

function setStats(builderConfig, webpackConfig) {
  // const isFullStats = !!builderConfig.optimize;
  const stats = {
    // assets: isFullStats,
    // children: isFullStats,
    // chunks: isFullStats,
    colors: true,
    errorDetails: true,
    errors: true,
    // hash: isFullStats,
    modules: false,
    // publicPath: isFullStats,
    // reasons: isFullStats,
    // source: isFullStats,
    timings: true,
    // version: isFullStats,
    warnings: true,
  };
  return _.set('stats', stats, webpackConfig);
}

module.exports = _.curry(setStats);
