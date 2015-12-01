// Webpack configuration for server bundle

const webpack = require('webpack');
const path = require('path');
const React = require('react')

const devBuild = process.env.NODE_ENV !== 'production';
const nodeEnv = devBuild ? 'development' : 'production';

const serverEntry = React.version >= '0.14' ? [
  './app/bundles/HelloWorld/startup/serverGlobals', 'react-dom/server', 'react'] : ['./app/bundles/HelloWorld/startup/serverGlobals']

module.exports = {

  // the project dir
  context: __dirname,
  entry: serverEntry,
  output: {
    filename: 'server-bundle.js',
    path: '../app/assets/javascripts/generated',
  },
  resolve: {
    extensions: ['', '.webpack.js', '.web.js', '.js', '.jsx', 'config.js'],
    alias: {
      lib: path.join(process.cwd(), 'app', 'lib'),
    },
  },
  plugins: [
    new webpack.DefinePlugin({
      'process.env': {
        NODE_ENV: JSON.stringify('production'),
      },
    }),
  ],
  module: {
    loaders: [
      {test: /\.jsx?$/, loader: 'babel-loader', exclude: /node_modules/},

      // React is necessary for the client rendering:
      {test: require.resolve('react'), loader: 'expose?React'},
      {test: require.resolve('react-dom/server'), loader: 'expose?ReactDOMServer'},
    ],
  },
};
