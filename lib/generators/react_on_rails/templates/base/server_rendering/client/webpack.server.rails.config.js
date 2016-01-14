// Webpack configuration for server bundle

const webpack = require('webpack');
const path = require('path');

const devBuild = process.env.NODE_ENV !== 'production';
const nodeEnv = devBuild ? 'development' : 'production';

module.exports = {

  // the project dir
  context: __dirname,
  entry: [
    'babel-polyfill',
    './app/bundles/HelloWorld/startup/serverRegistration',
  ],
  output: {
    filename: 'server-bundle.js',
    path: '../app/assets/javascripts/generated',
  },
  resolve: {
    extensions: ['', '.js', '.jsx'],
    alias: {
      lib: path.join(process.cwd(), 'app', 'lib'),
    },
  },
  plugins: [
    new webpack.DefinePlugin({
      'process.env': {
        NODE_ENV: JSON.stringify(nodeEnv),
      },
    }),
  ],
  module: {
    loaders: [
      { test: /\.jsx?$/, loader: 'babel-loader', exclude: /node_modules/ },
    ],
  },
};
