const path = require('path');

module.exports = {
  entry: [
    'startup/serverRegistration'
  ],
  output: {
    path: '../app/assets/javascripts/generated',
    filename: 'server.js',
  },
  resolve: {
    root: [path.join(__dirname, 'app')],
    extensions: ['', '.js', '.jsx'],
    fallback: [path.join(__dirname, 'node_modules')]
  },
  module: {
    loaders: [
      {test: /\.jsx?$/, loader: 'babel-loader', exclude: /node_modules/}

      // See client/app/startup/serverGlobals.jsx and client/apps/startup/clientGlobals.jsx
      // for configuration of how to expose your components for both server and client rendering.
    ],
  },
};
