// Common webpack configuration for server bundle
/* eslint-disable comma-dangle */

const webpack = require('webpack');
const path = require('path');

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
    path: '../app/assets/webpack',
  },
  resolve: {
    extensions: ['.js', '.jsx'],
    alias: {
      libs: path.join(process.cwd(), 'app', 'libs'),
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
