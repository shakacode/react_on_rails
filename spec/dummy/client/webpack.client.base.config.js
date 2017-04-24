// Common client-side webpack configuration used by
// webpack.client.rails.hot.config and webpack.client.rails.build.config.

const webpack = require('webpack');
const { resolve, join } = require('path');
const webpackCommon = require('./webpack.common');
const { assetLoaderRules } = webpackCommon;

const ManifestPlugin = require('webpack-manifest-plugin');
const webpackConfigLoader = require('react-on-rails').default.webpackConfigLoader;
const { env, paths, publicPath } = webpackConfigLoader(resolve('..', 'config', 'webpack'));

const manifestPath = resolve('..', paths.output, paths.assets, paths.manifest);

const devBuild = process.env.NODE_ENV !== 'production';

// console.log("COOONFIIGGG", config);
let sharedManifest = {};
try {
  sharedManifest = require(manifestPath);
} catch (ex) {
  console.info('No manifest found. It will be created at:', manifestPath);
}

module.exports = {

  // the project dir
  context: resolve(__dirname),
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
      images: join(process.cwd(), 'app', 'assets', 'images'),
      // 'react-on-rails': resolve(__dirname, '..', '..', '..'),
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
    new ManifestPlugin({ fileName: paths.manifest, publicPath, writeToFileEmit: true, cache: sharedManifest }),
  ],

  module: {
    rules: [
      ...assetLoaderRules,

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
