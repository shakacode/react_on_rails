const _ = require('lodash/fp');
const { config } = require('@rails/webpacker');

const serverBundleOutput = () => ({
  filename: 'server-bundle.js',
  path: config.outputPath,
  publicPath: config.outputPath,
  libraryTarget: 'commonjs2',
});

const normalOutput = () => {
  // See webpacker/package/environments/base.js
  const result = {
    filename: '[name].[hash].js',
    chunkFilename: '[name]-[contenthash].chunk.js',
    path: config.outputPath,
    publicPath: config.publicPath,
  };

  return result;
};

function setOutput(builderConfig, webpackConfig) {
  const output = _.cond([
    [_.get('serverRendering'), serverBundleOutput],
    [_.constant(true), normalOutput],
  ])(builderConfig);

  return _.set('output', output, webpackConfig);
}

module.exports = _.curry(setOutput);
