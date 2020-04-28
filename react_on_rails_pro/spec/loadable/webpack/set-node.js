const _ = require('lodash/fp');

function setNode(builderConfig, webpackConfig) {
  let node;
  if (!builderConfig.serverRendering) {
    node = {
      // Prevent bad fs import in graphql-ruby-client dependency
      // https://github.com/webpack-contrib/css-loader/issues/447#issuecomment-285598881
      fs: 'empty',
    };
  } else {
    // server rendering, we don't want polyfills
    node = false;
  }
  return _.set('node', node, webpackConfig);
}

module.exports = _.curry(setNode);
