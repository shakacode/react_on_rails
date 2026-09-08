// The source code including full typescript support is available at:
// https://github.com/shakacode/react-on-rails-demo-ssr-hmr/blob/master/config/webpack/commonWebpackConfig.js

// Common configuration applying to client and server configuration
const { generateWebpackConfig, merge } = require('shakapacker');

const baseClientWebpackConfig = generateWebpackConfig();

const commonOptions = {
  resolve: {
    extensions: ['.css', '.ts', '.tsx'],
  },
};

// Copy the object using merge b/c the baseClientWebpackConfig and commonOptions are mutable globals
const commonWebpackConfig = () => {
  const webpackConfig = merge({}, baseClientWebpackConfig, commonOptions);
  return webpackConfig;
};

module.exports = commonWebpackConfig;
