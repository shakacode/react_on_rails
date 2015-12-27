const path = require('path');

module.exports = {
  entry: [
    'es5-shim/es5-shim',
    'es5-shim/es5-sham',
    'startup/clientGlobals',
  ],
  output: {
    path: '../app/assets/javascripts/generated',
    filename: 'client.js',
  },
  resolve: {
    root: [path.join(__dirname, 'app')],
    extensions: ['', '.js', '.jsx'],
    fallback: [path.join(__dirname, 'node_modules')]
  },
  // same issue, for loaders like babel
  resolveLoader: {
    fallback: [path.join(__dirname, 'node_modules')]
  },
  module: {
    loaders: [
      { test: /\.jsx?$/, loader: 'babel-loader', exclude: /node_modules/ },
    ],
  },
};
