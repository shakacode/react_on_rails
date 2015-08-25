const path = require('path');

module.exports = {
  context: __dirname,
  entry: [
    'startup/serverGlobals',
  ],
  output: {
    path: '../app/assets/javascripts/generated',
    filename: 'server.js',

    // CRITICAL for enabling Rails to find the globally exposed variables. See startup/serverGlobals.jsx
    libaryTarget: 'this',
  },
  resolve: {
    root: [path.join(__dirname, 'app')],
    extensions: ['', '.js', '.jsx'],
  },
  module: {
    loaders: [
      { loader: 'babel-loader' },

      // require Resolve must go first
      // 1. React must be exposed (BOILERPLATE)
      { test: require.resolve('react'), loader: 'expose?React' },

      // MANIFEST of what you expose for the server if you do it here in the config file.
      // However, we recommend using the pattern in /client/app/startup/serverGlobals.jsx
      //{ test: require.resolve('./app/HelloString.js'), loader: 'expose?HelloString' },
      //{ test: require.resolve('./app/startup/ServerApp.jsx'), loader: 'expose?App' },
    ],
  },
};
