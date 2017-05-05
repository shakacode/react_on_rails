// Common webpack configuration for server bundle
/* eslint-disable comma-dangle */

const webpack = require('webpack');
const { resolve, join } = require('path');
const webpackCommon = require('./webpack.common');
const { assetLoaderRules } = webpackCommon;

const webpackConfigLoader = require('react-on-rails/webpackConfigLoader');
const configPath = resolve('..', 'config', 'webpack');
const { paths } = webpackConfigLoader(configPath);

const devBuild = process.env.NODE_ENV !== 'production';
const nodeEnv = devBuild ? 'development' : 'production';

module.exports = {

  // the project dir
  context: __dirname,
  entry: [
    './app/startup/serverRegistration',
  ],
  output: {
    filename: 'server-bundle.js',
    path: resolve('..', paths.output, paths.assets),
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
