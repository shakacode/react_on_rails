// The source code including full typescript support is available at:
// https://github.com/shakacode/react-on-rails-demo-ssr-hmr/blob/master/config/webpack/commonWebpackConfig.js

// Common configuration applying to client and server configuration
const shakapacker = require('shakapacker');

const { config, merge } = shakapacker;
const baseClientWebpackConfig =
  config.assets_bundler === 'rspack'
    ? require('shakapacker/rspack').generateRspackConfig()
    : shakapacker.baseConfig;

const commonOptions = {
  resolve: {
    extensions: ['.css', '.ts', '.tsx'],
  },
};

// Copy the object using merge b/c the baseClientWebpackConfig and commonOptions are mutable globals
const commonWebpackConfig = () => merge({}, baseClientWebpackConfig, commonOptions);

module.exports = commonWebpackConfig;
