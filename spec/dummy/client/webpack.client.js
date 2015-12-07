const path = require('path');

module.exports = {
  entry: [
    'react-dom',
    'react_on_rails',
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
      { loader: 'babel-loader' },

      // React is necessary for the client rendering:
      { test: require.resolve('react'), loader: 'expose?React' },
      { test: require.resolve('react-dom'), loader: 'expose?ReactDOM' },
    ],
  },
};
