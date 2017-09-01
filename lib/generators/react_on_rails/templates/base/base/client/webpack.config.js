// For inspiration on your webpack configuration, see:
// https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/client
// https://github.com/shakacode/react-webpack-rails-tutorial/tree/master/client
//
// const webpack = require('webpack');
// const { resolve } = require('path');
// const { env } = require('process');
// const ManifestPlugin = require('webpack-manifest-plugin');
// const webpackConfigLoader = require('react-on-rails/webpackConfigLoader');
//
// const configPath = resolve('..', 'config');
// const { settings, output } = webpackConfigLoader(configPath);
//
// const config = {
//
//   context: resolve(__dirname),
//
//   entry: {
//     'hello-world-bundle': [
//       'es5-shim/es5-shim',
//       'es5-shim/es5-sham',
//       'babel-polyfill',
//       './app/bundles/HelloWorld/startup/registration',
//     ],
//   },
//
//   devtool: 'cheap-eval-source-map',
//
//   output: {
//     pathinfo: true
//   },
//
//   devServer: {
//     clientLogLevel: 'none',
//     host: settings.dev_server.host,
//     port: settings.dev_server.port,
//     https: settings.dev_server.https,
//     hot: settings.dev_server.hmr,
//     contentBase: output.path,
//     publicPath: output.publicPath,
//     compress: true,
//     headers: { 'Access-Control-Allow-Origin': '*' },
//     historyApiFallback: true,
//     watchOptions: {
//       ignored: /node_modules/
//     },
//     stats: {
//       errorDetails: true
//     }
//   },
//
//   output: {
//     // Name comes from the entry section.
//     filename: '[name]-[hash].js',
//
//     // Leading slash is necessary
//     publicPath: `/${output.publicPath}`,
//     path: output.path,
//   },
//
//   resolve: {
//     extensions: ['.js', '.jsx'],
//   },
//
//   plugins: [
//     new webpack.EnvironmentPlugin({
//       NODE_ENV: 'development', // use 'development' unless process.env.NODE_ENV is defined
//       DEBUG: false,
//     }),
//     new ManifestPlugin({
//       publicPath: output.publicPath,
//       writeToFileEmit: true }),
//   ],
//   module: {
//     rules: [
//       {
//         test: require.resolve('react'),
//         use: {
//           loader: 'imports-loader',
//           options: {
//             shim: 'es5-shim/es5-shim',
//             sham: 'es5-shim/es5-sham',
//           },
//         },
//       },
//       {
//         test: /\.jsx?$/,
//         use: 'babel-loader',
//         exclude: /node_modules/,
//       },
//     ],
//   },
// };
//
// if (env.NODE_ENV == 'development') {
//   if (settings.dev_server.hmr) {
//     config.plugins.push(new webpack.HotModuleReplacementPlugin());
//   } else {
//     config.plugins.push(new webpack.NamedModulesPlugin());
//   }
// }
//
// const devBuild = (env.NODE_ENV !== 'development');
//
//
// if (devBuild) {
//   console.log('Webpack dev build for Rails'); // eslint-disable-line no-console
//   config.devtool = 'eval-source-map';
// } else {
//   console.log('Webpack production build for Rails'); // eslint-disable-line no-console
// }
//
// module.exports = config;
//


// config/webpack/server.js
const { environment } = require('@rails/webpacker');

const config = environment.toWebpackConfig();
config.entry = {
  'hello-world-bundle': [
    'es5-shim/es5-shim',
    'es5-shim/es5-sham',
    'babel-polyfill',
    './app/bundles/HelloWorld/startup/registration',
  ],
};
module.exports = config;
