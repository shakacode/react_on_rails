const path = require('path');

module.exports = {
  entry: [
    'es5-shim/es5-shim',
    'es5-shim/es5-sham',
    'startup/serverGlobals'
  ],
  output: {
    path: '../app/assets/javascripts/generated',
    filename: 'server.js',

    // CRITICAL to set libraryTarget: 'this' for enabling Rails to find the exposed modules IF you
    //   use the "expose" webpackfunctionality. See startup/serverGlobals.jsx.
    // NOTE: This is NOT necessary if you use the syntax of global.MyComponent = MyComponent syntax.
    // See http://webpack.github.io/docs/configuration.html#externals for documentation of this option
    //libraryTarget: 'this',
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
