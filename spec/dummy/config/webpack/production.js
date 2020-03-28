process.env.NODE_ENV = process.env.NODE_ENV || 'production';

// We need to compile both our production JS (for serving to the client) and our server JS
// (for SSR of React components). This is easy enough as we can export arrays of webpack configs.
const clientEnvironment = require('./client');
const serverConf = require('./server');
const merge = require('webpack-merge');

clientEnvironment.splitChunks((config) =>
  Object.assign({}, config, { optimization: { splitChunks: false } }),
);

const clientConfig = merge(clientEnvironment.toWebpackConfig(), {
  mode: 'production',
  entry: {
    'vendor-bundle': ['jquery-ujs'],
    output: {
      filename: '[name].js',
      chunkFilename: '[name].bundle.js',
      path: clientEnvironment.config.output.path,
    },
  },
  devtool: 'inline-source-map',
});

// Overriding the mode for production
const serverConfig = merge(serverConf, {
  mode: 'production',
});

module.exports = [clientConfig, serverConfig];
