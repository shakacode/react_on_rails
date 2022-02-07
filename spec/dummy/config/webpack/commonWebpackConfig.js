// Common configuration applying to client and server configuration
const { webpackConfig: baseClientWebpackConfig, merge } = require('shakapacker');

const webpack = require('webpack');

const aliasConfig = require('./alias.js');

const commonOptions = {
  resolve: {
    extensions: ['.css', '.ts', '.tsx'],
  },
};

// add sass resource loader
const sassLoaderConfig = {
  loader: 'sass-resources-loader',
  options: {
    resources: './client/app/assets/styles/app-variables.scss',
  },
};

const scssConfigIndex = baseClientWebpackConfig.module.rules.findIndex((config) =>
  '.scss'.match(config.test),
);
baseClientWebpackConfig.module.rules[scssConfigIndex].use.push(sassLoaderConfig);

// add jquery
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

baseClientWebpackConfig.module.rules.push(exposeJQuery, jqueryUjsLoader);

const commonWebpackConfig = () => merge({}, baseClientWebpackConfig, commonOptions, aliasConfig);

module.exports = commonWebpackConfig;
