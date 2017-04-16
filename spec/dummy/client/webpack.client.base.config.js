// Common client-side webpack configuration used by
// webpack.client.rails.hot.config and webpack.client.rails.build.config.

const webpack = require('webpack');
const { resolve, join } = require('path');
const webpackCommon = require('./webpack.common');
const { assetLoaderRules } = webpackCommon;

const ManifestPlugin = require('webpack-manifest-plugin');
const { env, paths, publicPath } = require('./webpackConfigLoader.js');
const manifestPath = resolve('..', paths.output, paths.assets, paths.manifest);

const devBuild = process.env.NODE_ENV !== 'production';

let sharedManifest = {};
try {
  sharedManifest = require(manifestPath);
} catch (ex) {
  console.error(ex);
  console.log('Make sure the client build (client.base.build or client.rails.build) creates a manifest in:', manifestPath);
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
    // modules: [
    //   paths.source,
    //   paths.node_modules,
    // ],
    alias: {
      images: join(process.cwd(), 'app', 'assets', 'images'),
    },
  },

  resolveLoader: {
    modules: [paths.node_modules],
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
