const _ = require('lodash/fp');
const TerserPlugin = require('terser-webpack-plugin');

const { addOption } = require('./utils');

function setOptimization(builderConfig, webpackConfig) {
  const ifClient = (option) => addOption(!builderConfig.serverRendering, option);

  const optimization = {
    minimize: builderConfig.optimize,
    // using terser minimizer by default
    // https://github.com/webpack-contrib/terser-webpack-plugin/issues/15#issuecomment-421388132
    /*
      webpack@5 will use terser plugin by default.
      My recommendation is switch to terser plugin ASAP.
    */
    minimizer: [
      new TerserPlugin({
        terserOptions: {
          parallel: true,
          compress: {
            comparisons: false,
            warnings: false,
          },
          output: {
            ascii_only: true,
            comments: false,
          },
        },
      }),
    ],
    ...ifClient(() => ({
      splitChunks: {
        cacheGroups: {
          vendor: {
            name: 'vendor',
            test: /[\\/]node_modules[\\/]/,
            priority: -10,
            chunks: 'all',
          },
        },
      },
    })),
  };
  return _.set('optimization', optimization, webpackConfig);
}

module.exports = _.curry(setOptimization);
