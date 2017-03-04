// Common client-side webpack configuration used by
// webpack.client.rails.hot.config and webpack.client.rails.build.config.

const webpack = require('webpack');
const path = require('path');

const devBuild = process.env.NODE_ENV !== 'production';

module.exports = {

  // the project dir
  context: __dirname,
  entry: {
    // This will contain the app entry points defined by
    // webpack.client.rails.hot.config and webpack.client.rails.build.config
    app: [
      './app/startup/clientRegistration',
    ],
  },
  resolve: {
    extensions: ['.js', '.jsx'],
    alias: {
      libs: path.join(process.cwd(), 'app', 'libs'),
    },
  },

  plugins: [
    new webpack.EnvironmentPlugin({ NODE_ENV: 'development' }),
    new webpack.DefinePlugin({
      TRACE_TURBOLINKS: devBuild,
    }),

    // https://webpack.js.org/guides/code-splitting-libraries/#implicit-common-vendor-chunk
    new webpack.optimize.CommonsChunkPlugin({
      name: 'vendor',
      minChunks(module) {
        // this assumes your vendor imports exist in the node_modules directory
        return module.context && module.context.indexOf('node_modules') !== -1;
      },
    }),
  ],

  module: {
    rules: [
      {
        test: /\.(ttf|eot)$/,
        use: 'file-loader',
      },

      // Example to confirm that subdirectories work
      {
        test: /\.(jpe?g|png|gif|svg|ico|woff2?)$/,
        use: {
          loader: 'url-loader',
          options: {
            limit: 10000,
            name: 'images/[hash].[ext]',
          },
        },
      },
      {
        test: require.resolve('jquery'),
        use: {
          loader: 'expose-loader',
          options: {
            jQuery: true,
          },
        },
      },
    ],
  },
};
