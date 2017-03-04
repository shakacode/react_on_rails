// Run like this:
// cd client && yarn run build:client
// Note that Foreman (Procfile.dev) has also been configured to take care of this.

/* eslint-disable comma-dangle */

const ExtractTextPlugin = require('extract-text-webpack-plugin');
const config = require('./webpack.client.base.config');

const devBuild = process.env.NODE_ENV !== 'production';

config.output = {
  filename: '[name]-bundle.js',
  path: '../app/assets/webpack',
  publicPath: '/assets/',
};

// See webpack.client.base.config for adding modules common to both the webpack dev server and rails

config.module.rules.push(
  {
    test: /\.jsx?$/,
    use: 'babel-loader',
    exclude: /node_modules/,
  },
  {
    test: /\.css$/,
    loader: ExtractTextPlugin.extract({
      fallback: 'style-loader',
      use: [
        {
          loader: 'css-loader',
          options: {
            minimize: true,
            modules: true,
            importLoaders: 1,
            localIdentName: '[name]__[local]__[hash:base64:5]',
          },
        },
        'postcss-loader',
      ],
    }),
  },
  {
    test: /\.scss$/,
    use: ExtractTextPlugin.extract({
      fallback: 'style-loader',
      loader: [
        {
          loader: 'css-loader',
          options: {
            minimize: true,
            modules: true,
            importLoaders: 3,
            localIdentName: '[name]__[local]__[hash:base64:5]',
          },
        },
        {
          loader: 'postcss-loader',
          options: {
            plugins: 'autoprefixer'
          }
        },
        'sass-loader',
        {
          loader: 'sass-resources-loader',
          options: {
            resources: './app/assets/styles/app-variables.scss'
          },
        }
      ],
    }),
  },
  {
    test: require.resolve('react'),
    use: {
      loader: 'imports-loader',
      options: {
        shim: 'es5-shim/es5-shim',
        sham: 'es5-shim/es5-sham',
      }
    }
  },
  {
    test: require.resolve('jquery-ujs'),
    use: {
      loader: 'imports-loader',
      options: {
        jQuery: 'jquery',
      }
    }
  }
);

config.plugins.push(
  new ExtractTextPlugin({
    filename: '[name]-bundle.css',
    allChunks: true
  })
);

if (devBuild) {
  console.log('Webpack dev build for Rails'); // eslint-disable-line no-console
  config.devtool = 'eval-source-map';
} else {
  console.log('Webpack production build for Rails'); // eslint-disable-line no-console
}

module.exports = config;
