process.env.NODE_ENV = process.env.NODE_ENV || 'test';

const clientEnvironment = require('./client');
const serverConfig = require('./server');
const merge = require('webpack-merge');

const clientConfig = merge(clientEnvironment.toWebpackConfig(), {
  mode: 'development',
  entry: {
    'vendor-bundle': ['jquery-ujs'],
  },
  output: {
    filename: '[name].js',
    chunkFilename: '[name].bundle.js',
    path: clientEnvironment.config.output.path,
  },
});

module.exports = [clientConfig, serverConfig];
