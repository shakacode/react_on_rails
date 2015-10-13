const path = require('path');

module.exports = {
  entry: [
    'startup/clientGlobals',
    'react',
  ],
  output: {
    path: '../app/assets/javascripts/generated',
    filename: 'client.js',
  },
  resolve: {
    root: [path.join(__dirname, 'app')],
    extensions: ['', '.js', '.jsx'],
  },
  module: {
    loaders: [
      { loader: 'babel-loader' },

      // React is necessary for the client rendering:
      { test: require.resolve('react'), loader: 'expose?React' },
    ],
  },
};
