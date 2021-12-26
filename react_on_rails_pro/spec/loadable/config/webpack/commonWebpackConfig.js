const { webpackConfig: baseClientWebpackConfig, merge } = require('@rails/webpacker');
const webpack = require('webpack');

const commonOptions = {
  resolve: {
    extensions: ['.css', '.ts', '.tsx'],
  },
};

const commonWebpackConfig = () => merge({}, baseClientWebpackConfig, commonOptions);

module.exports = commonWebpackConfig;
