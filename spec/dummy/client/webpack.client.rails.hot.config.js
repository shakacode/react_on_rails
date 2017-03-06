// Run with Rails server like this:
// rails s
// cd client && babel-node server-rails-hot.js
// Note that Foreman (Procfile.dev) has also been configured to take care of this.
/* eslint-disable comma-dangle */

const path = require('path');
const webpack = require('webpack');

const config = require('./webpack.client.base.config');

const hotRailsPort = process.env.HOT_RAILS_PORT || 3500;

config.entry.app.push(
  `webpack-dev-server/client?http://localhost:${hotRailsPort}`,
  'webpack/hot/only-dev-server'
);

config.output = {
  filename: '[name]-bundle.js',
  path: path.join(__dirname, 'public'),
  publicPath: `http://localhost:${hotRailsPort}/`,
};

config.module.rules.push(
  {
    test: /\.jsx?$/,
    loader: 'babel',
    exclude: /node_modules/,
    query: {
      plugins: [
        [
          'react-transform',
          {
            transforms: [
              {
                transform: 'react-transform-hmr',
                imports: ['react'],
                locals: ['module'],
              },
            ],
          },
        ],
      ],
    },
  },
  {
    test: /\.css$/,
    use: [
      {
        loader: 'css-loader',
        options: {
          modules: true,
          importLoaders: 0,
          localIdentName: '[name]__[local]__[hash:base64:5]'
        }
      },
      {
        loader: 'postcss-loader',
        options: {
          plugins: 'autoprefixer'
        }
      }
    ]
  },
  {
    test: /\.scss$/,
    use: [
      {
        loader: 'css-loader',
        options: {
          modules: true,
          importLoaders: 3,
          localIdentName: '[name]__[local]__[hash:base64:5]',
        }
      },
      {
        loader: 'postcss-loader',
        options: {
          plugins: 'autoprefixer'
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
  new webpack.HotModuleReplacementPlugin(),
  new webpack.NoErrorsPlugin()
);

config.devtool = 'eval-source-map';

console.log('Webpack HOT dev build for Rails'); // eslint-disable-line no-console

module.exports = config;
