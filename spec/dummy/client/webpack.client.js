const path = require('path');

module.exports = {
  entry: [
    'es5-shim/es5-shim', // for poltergeist
    'es5-shim/es5-sham', // for poltergeist
    'babel-polyfill',
    'jquery',
    'jquery-ujs',
    'startup/clientRegistration',
  ],
  output: {
    path: '../app/assets/javascripts/generated',
    filename: 'client.js',
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

  // same issue, for loaders like babel
  resolveLoader: {
    fallback: [path.join(__dirname, 'node_modules')],
  },
  module: {
    loaders: [
      { test: /\.jsx?$/, loader: 'babel-loader', exclude: /node_modules/ },
      { test: require.resolve('jquery'), loader: 'expose?jQuery' },
      { test: require.resolve('jquery'), loader: 'expose?$' },
    ],
  },
};
