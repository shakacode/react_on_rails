const _ = require('lodash/fp');
const { config, devServer } = require('@rails/webpacker');
const LoadablePlugin = require('@loadable/webpack-plugin');

const webpack = require('webpack');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');

const WebpackAssetsManifest = require('webpack-assets-manifest');
const CaseSensitivePathsPlugin = require('case-sensitive-paths-webpack-plugin');

const CompressionPlugin = require('compression-webpack-plugin');
const CircularDependencyPlugin = require('circular-dependency-plugin');
const ReactRefreshWebpackPlugin = require('@pmmmwh/react-refresh-webpack-plugin');

const { addOption, getEnvVar, removeEmpty } = require('./utils');

function setPlugins(builderConfig, webpackConfig) {
  const ifOptimize = (option) => addOption(builderConfig.optimize, option);
  const ifDebug = (option) => addOption(builderConfig.debug, option);
  const ifExtractCss = (option) => addOption(builderConfig.extractCss, option);
  const ifUseHmr = (option) =>
    addOption(!builderConfig.serverRendering && builderConfig.devServer && devServer.hmr, option);

  const ifEnvHmr = (option) => addOption(process.env.HMR === 'true', option);
  const ifServerRendering = (option) => addOption(builderConfig.serverRendering, option);
  const unlessServerRendering = (option) => addOption(!builderConfig.serverRendering, option);
  const unlessServerRenderingAndNotHmr = (option) =>
    addOption(!builderConfig.serverRendering && process.env.HMR !== 'true', option);

  const shouldUseNotifierPlugin =
    builderConfig.developerAids && !builderConfig.serverRendering && !process.env.NO_WEBPACK_NOTIFIER;

  const WebpackNotifierPlugin = shouldUseNotifierPlugin
    ? require('webpack-notifier') // eslint-disable-line import/no-extraneous-dependencies,global-require,max-len
    : null;

  const ifPluginSourceMaps = (option) => addOption(builderConfig.sourceMaps === 'plugin', option);

  const plugins = removeEmpty([
    WebpackNotifierPlugin ? new WebpackNotifierPlugin({ alwaysNotify: true }) : null,

    ifPluginSourceMaps(
      () =>
        new webpack.SourceMapDevToolPlugin({
          filename: '[name]-[hash].js.map',
          exclude: ['vendor'],
        }),
    ),

    // From https://github.com/rails/webpacker/blob/master/package/environments/base.js#L35
    new CaseSensitivePathsPlugin(),

    // The old react plugin
    // ifUseHmr(
    //   () => new webpack.HotModuleReplacementPlugin()
    // ),

    // the new plugin
    ifUseHmr(
      () =>
        new ReactRefreshWebpackPlugin({
          // https://github.com/pmmmwh/react-refresh-webpack-plugin/issues/11
          // https://github.com/pmmmwh/react-refresh-webpack-plugin/issues/15
          disableRefreshCheck: true,
        }),
    ),

    // See docs/loadable-components.md for details.
    ifEnvHmr(
      () =>
        new webpack.NormalModuleReplacementPlugin(/(.*)\.imports-loadable(\.jsx)?/, (resource) => {
          /* eslint-disable no-param-reassign */
          resource.request = resource.request.replace(/imports-loadable/, 'imports-hmr');
          /* eslint-enable no-param-reassign */
          return resource.request;
        }),
    ),

    ifDebug(
      () =>
        new CircularDependencyPlugin({
          cwd: process.cwd(),
          exclude: /node_modules/,
          failOnError: true,
          // onDetected({ paths, compilation }) {
          //   if (paths.some(p => p.includes('listings/leaf'))) {
          //     compilation.errors.push(new Error(paths.join(' -> ')));
          //   }
          // },
        }),
    ),

    new webpack.DefinePlugin({
      'process.env': {
        NODE_ENV: getEnvVar('NODE_ENV'),
        RAILS_ENV: getEnvVar('RAILS_ENV'),
        HMR: getEnvVar('HMR'),
      },
    }),

    // See webpacker/package/environments/base.js
    unlessServerRendering(
      () =>
        new WebpackAssetsManifest({
          integrity: false,
          entrypoints: true,
          writeToDisk: true,
          publicPath: config.publicPathWithoutCDN,
        }),
    ),

    unlessServerRenderingAndNotHmr(
      // writeToDisk https://github.com/gregberge/loadable-components/pull/161
      () => new LoadablePlugin({ filename: 'loadable-stats.json', writeToDisk: true }),
    ),

    ifServerRendering(
      () =>
        new webpack.optimize.LimitChunkCountPlugin({
          maxChunks: 1,
        }),
    ),

    ifOptimize(() => new CompressionPlugin()),

    ifExtractCss(
      () =>
        new MiniCssExtractPlugin({
          filename: '[name].[contenthash].css',
        }),
    ),
  ]);

  return _.set('plugins', plugins, webpackConfig);
}

module.exports = _.curry(setPlugins);
