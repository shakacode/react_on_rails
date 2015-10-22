// https://github.com/shakacode/react-webpack-rails-tutorial/blob/master/client/webpack.client.rails.config.js
// Run like this:
// cd client && npm run build:dev
// Note that Foreman (Procfile.dev) has also been configured to take care of this.

// NOTE: All style sheets handled by the asset pipeline in rails

const webpack = require('webpack');
const config = require('./webpack.client.base.config');

const devBuild = process.env.NODE_ENV !== 'production';

config.output = {
  filename: '[name]-bundle.js',
  path: '../app/assets/javascripts/generated',
};

// You can add entry points specific to rails here
config.entry.vendor.unshift(
  'es5-shim/es5-shim',
  'es5-shim/es5-sham'
);
config.entry.app.push('./app/startup/clientGlobals');

// See webpack.common.config for adding modules common to both the webpack dev server and rails

config.module.loaders.push(
  {test: /\.jsx?$/, loader: 'babel-loader', exclude: /node_modules/}
);

module.exports = config;

if (devBuild) {
  console.log('Webpack dev build for Rails'); // eslint-disable-line no-console
  module.exports.devtool = 'eval-source-map';
} else {
  config.plugins.push(
    new webpack.DefinePlugin({
      'process.env': {
        NODE_ENV: JSON.stringify('production'),
      },
    }),
    new webpack.optimize.DedupePlugin()
  );
  console.log('Webpack production build for Rails'); // eslint-disable-line no-console
}
