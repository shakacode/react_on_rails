/* eslint comma-dangle: ["error",
 {"functions": "never", "arrays": "only-multiline", "objects":
 "only-multiline"} ] */

const webpack = require('webpack');
const { resolve } = require('path');
const ManifestPlugin = require('webpack-manifest-plugin');
const webpackConfigLoader = require('react-on-rails/webpackConfigLoader');

const configPath = resolve('..', 'config', 'webpack');
const { env, paths, publicPath } = webpackConfigLoader(configPath);

const devBuild = env !== 'production';

const config = {

  context: resolve(__dirname),

  entry: [
    'es5-shim/es5-shim',
    'es5-shim/es5-sham',
    'babel-polyfill',
    './app/bundles/HelloWorld/startup/registration',
  ],

  output: {
    filename: 'webpack-bundle.js',
    path: resolve('..', paths.output, paths.assets),
  },

  resolve: {
    extensions: ['.js', '.jsx'],
  },


  plugins: [
    new webpack.EnvironmentPlugin(JSON.parse(JSON.stringify(env))),
    new ManifestPlugin({ fileName: paths.manifest, publicPath, writeToFileEmit: true }),
  ],

  module: {
    rules: [
      {
        test: require.resolve('react'),
        use: {
          loader: 'imports-loader',
          options: {
            shim: 'es5-shim/es5-shim',
            sham: 'es5-shim/es5-sham',
          }
        },
      },
      {
        test: /\.jsx?$/,
        use: 'babel-loader',
        exclude: /node_modules/,
      },
    ],
  },
};

module.exports = config;

if (devBuild) {
  console.log('Webpack dev build for Rails'); // eslint-disable-line no-console
  module.exports.devtool = 'eval-source-map';
} else {
  console.log('Webpack production build for Rails'); // eslint-disable-line no-console
}
