// Common configuration applying to client and server configuration
const { webpackConfig: baseClientWebpackConfig, merge } = require('@rails/webpacker');

const webpack = require('webpack');
const { resolve } = require('path');

const aliasConfig = require('./alias.js');

const commonOptions = {
  resolve: {
    extensions: ['.css', '.ts', '.tsx'],
  },
};

const fileLoader = {
  test: /(.jpg|.jpeg|.png|.gif|.tiff|.ico|.svg|.eot|.otf|.svg|.ttf|.woff|.woff2|.ttf|.eot|.svg)$/i,
  use: [
    {
      loader: 'file-loader',
      options: {
        esModule: false,
        context: 'client/app',
      },
    },
  ],
};

const urlFileSizeCutover = 10000;

const urlLoaderOptions = Object.assign(
  { limit: urlFileSizeCutover, esModule: false },
  fileLoader.use[0].options,
);

const urlLoader = {
  test: fileLoader.test,
  use: {
    loader: 'url-loader',
    options: urlLoaderOptions,
  },
};

const root = resolve(__dirname, '../../client/app');
const resolveUrlLoader = {
  loader: 'resolve-url-loader',
  options: {
    root,
  },
};

const exposeJQuery = {
  test: require.resolve('jquery'),
  use: [{ loader: 'expose-loader', options: { exposes: ['$', 'jQuery'] } }],
};

const jqueryUjsLoader = {
  test: require.resolve('jquery-ujs'),
  use: [{ loader: 'imports-loader', options: { type: 'commonjs', imports: 'single jquery jQuery' } }],
};

baseClientWebpackConfig.plugins.push(
  new webpack.ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery',
  }),
);

baseClientWebpackConfig.module.rules.push(urlLoader, exposeJQuery, jqueryUjsLoader, fileLoader);

const commonWebpackConfig = () => merge({}, baseClientWebpackConfig, commonOptions);

module.exports = commonWebpackConfig;
