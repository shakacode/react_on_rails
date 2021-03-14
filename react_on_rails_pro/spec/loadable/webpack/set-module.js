const path = require('path');
const _ = require('lodash/fp');
const { devServer } = require('@rails/webpacker');

function setModule(builderConfig, webpackConfig) {
  const isDevelopment = process.env.NODE_ENV !== 'production';
  const useHmr = isDevelopment && builderConfig.devServer && devServer.hmr;
  const urlFileSizeCutover = 10 * 1024; // below 10k, inline
  const babelOptions = {
    configFile: false,
    babelrc: false,
    presets: [
      [
        '@babel/preset-env',
        {
          exclude: ['@babel/plugin-transform-typeof-symbol'],
          ignoreBrowserslistConfig: true,
          modules: false,
          targets: {
            ie: '9',
            safari: '11',
          },
          useBuiltIns: false,
        },
      ],
      [
        '@babel/preset-react',
        {
          useBuiltIns: true,
        },
      ],
    ],
    plugins: [
      !useHmr && '@loadable/babel-plugin',
      'inline-react-svg',
      [
        '@babel/plugin-proposal-class-properties',
        {
          loose: true,
        },
      ],
      [
        '@babel/plugin-proposal-object-rest-spread',
        {
          useBuiltIns: true,
        },
      ],
      '@babel/plugin-syntax-dynamic-import',
      '@babel/plugin-transform-arrow-functions',
      '@babel/plugin-transform-async-to-generator',
      '@babel/plugin-transform-destructuring',
      '@babel/plugin-transform-regenerator',
      [
        '@babel/plugin-transform-runtime',
        {
          corejs: false,
          helpers: true,
          regenerator: true,
          useESModules: true,
          // By default, the plugin assumes @babel/runtime@7.0.0. Since we use >7.0.0, better to
          // explicitly specify the version so that it can reuse the helper better
          // See https://github.com/babel/babel/issues/10261
          version: require('@babel/runtime/package.json').version,
        },
      ],
      useHmr && 'react-refresh/babel',
    ].filter(Boolean),
    cacheDirectory: 'tmp/cache/webpacker/babel-loader-node-modules',
    cacheCompression: false,
    compact: false,
    sourceMaps: false,
  };
  const webpackModule = {
    // makes missing exports an error instead of warning
    strictExportPresence: true,
    rules: [
      {
        test: /\.(js|jsx|mjs)$/,
        include: [path.resolve(__dirname, 'app/javascript'), /node_modules/],
        exclude: /node_modules\/(?!d3|intl-messageformat|intl-messageformat-parser|react-form|react-intl|sift).+/,
        use: [
          {
            loader: 'babel-loader',
            options: babelOptions,
          },
        ],
      },
      {
        test: /\.jsx?$/,
        use: [
          {
            loader: 'babel-loader',
            options: babelOptions,
          },
        ],
        exclude: /node_modules/,
      },
      {
        test: /\.css$/,
        use: builderConfig.serverRendering
          ? {
              loader: 'css-loader',
              options: {
                modules: true,
                importLoaders: 0,
              },
            }
          : [
              'style-loader',
              {
                loader: 'css-loader',
                options: {
                  modules: true,
                  importLoaders: 1,
                },
              },
            ],
      },
      /* example configuration
      // Support loading .gql files as GraphQL queries/mutations/fragments
      // https://github.com/apollographql/graphql-tag#webpack-preprocessing-with-graphql-tagloader
      {
        test: /\.(graphql|gql)$/,
        exclude: /node_modules/,
        loader: 'graphql-tag/loader',
      },
      {
        test: /\.woff2?$/,
        use: {
          loader: 'url-loader',
          options: {
            name: '[name].[hash].[ext]',
            limit: urlFileSizeCutover,
            publicPath: `/webpack/${process.env.NODE_ENV}/`,
          },
        },
      },
      {
        test: /\.(jpe?g|png|gif|ico)$/,
        use: {
          loader: 'url-loader',
          options: {
            name: '[name].[hash].[ext]',
            limit: urlFileSizeCutover,
            publicPath: `/webpack/${process.env.NODE_ENV}/`,
          },
        },
      },
      {
        test: /\.(ttf|eot)$/,
        use: {
          loader: 'file-loader',
          options: {
            name: '[name].[hash].[ext]',
            publicPath: `/webpack/${process.env.NODE_ENV}/`,
          },
        },
      },*/
    ],
  };

  return _.set('module', webpackModule, webpackConfig);
}

module.exports = _.curry(setModule);
