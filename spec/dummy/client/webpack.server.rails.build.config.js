// Common webpack configuration for server bundle
const { resolve, join } = require('path');
const webpack = require('webpack');
const webpackCommon = require('./webpack.common.config');
const { assetLoaderRules } = webpackCommon;

const webpackConfigLoader = require('react-on-rails/webpackConfigLoader');
const configPath = resolve('..', 'config');
const { webpackOutputPath, webpackPublicOutputDir } = webpackConfigLoader(configPath);

const devBuild = process.env.NODE_ENV !== 'production';
const nodeEnv = devBuild ? 'development' : 'production';

module.exports = {

  // the project dir
  context: __dirname,
  entry: [
    './app/startup/serverRegistration',
  ],
  output: {
    // Important to NOT use a hash if the server webpack config runs separately from the client one.
    // Otherwise, both would be writing to the same manifest.json file.
    // Additionally, there's no particular need to have a fingerprint (hash) on the server bundle,
    // since it's not cached by the browsers.
    filename: 'server-bundle.js',

    // Leading and trailing slashes ARE necessary.
    publicPath: '/' + webpackPublicOutputDir + '/',
    path: webpackOutputPath,
  },
  resolve: {
    extensions: ['.js', '.jsx'],
    alias: {
      images: join(process.cwd(), 'app', 'assets', 'images'),
    },
  },

  plugins: [
    new webpack.DefinePlugin({
      'process.env': {
        NODE_ENV: JSON.stringify(nodeEnv),
      },
    }),
  ],
  module: {
    rules: [
      ...assetLoaderRules,
      {
        test: /\.jsx?$/,
        use: 'babel-loader',
        exclude: /node_modules/,
      },
      {
        test: /\.css$/,
        use: {
          loader: 'css-loader/locals',
          options: {
            modules: true,
            importLoaders: 0,
            localIdentName: '[name]__[local]__[hash:base64:5]'
          }
        }
      },
      {
        test: /\.scss$/,
        use: [
          {
            loader: 'css-loader/locals',
            options: {
              modules: true,
              importLoaders: 2,
              localIdentName: '[name]__[local]__[hash:base64:5]',
            }
          },
          {
            loader: 'sass-loader'
          },
          {
            loader: 'sass-resources-loader',
            options: {
              resources: './app/assets/styles/app-variables.scss'
            },
          }
        ],
      },
    ],
  },
};
