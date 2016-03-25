const path = require('path');

module.exports = {
  entry: [
    'babel-polyfill',
    'startup/server',
    'startup/alternative-server',
  ],
  output: {
    path: '../app/assets/webpack',
    filename: '[name]-bundle.js',
  },
  resolve: {
    root: [path.join(__dirname, 'app')],
    extensions: ['', '.js', '.jsx'],
    fallback: [path.join(__dirname, 'node_modules')],
    alias: {
      react: path.resolve('./node_modules/react'),
      'react-dom': path.resolve('./node_modules/react-dom'),
    },
  },
  module: {
    loaders: [
      { test: /\.jsx?$/, loader: 'babel-loader', exclude: /node_modules/ },
    ],
  },
};
