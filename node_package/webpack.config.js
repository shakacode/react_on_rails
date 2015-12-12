const webpack = require('webpack');
const fs = require('fs');
const path = require('path')

module.exports = {
  context: __dirname,
  entry: {
    ReactOnRails: ['babel-polyfill', './src/react_on_rails.js'],
  },
  resolve: {
    extensions: ['', '.js', '.jsx'],
  },

  output: {
    filename: 'react_on_rails.js',
    path: path.resolve(__dirname, "./lib"),
    libraryTarget: 'umd',
  },
  externals: [ 'react', 'react-dom', 'react-dom/server'],

  devtool: '#sourcemap',

  plugins: [
    new webpack.BannerPlugin(
      'require("source-map-support").install();',
      { raw: true, entryOnly: false }
    ),
  ],
  resolveLoader: {
    fallback: [path.join(__dirname, 'node_modules')]
  },
  module: {
    loaders: [
      {
        loader: "babel-loader",
        include: [
          path.resolve(__dirname, "./src"),
        ],
        test: /\.js$/,
        query: {
          plugins: ['transform-runtime'],
          presets: ['es2015', 'stage-0', 'react'],
        }
      },
    ],
  },
  debug: true
};