process.env.NODE_ENV = process.env.NODE_ENV || 'development'

const ForkTsCheckerWebpackPlugin = require('fork-ts-checker-webpack-plugin')
const path = require('path')
const { devServer, inliningCss } = require('@rails/webpacker')

const webpackConfig = require('./webpackConfig')

const developmentEnvOnly = (clientWebpackConfig, serverWebpackConfig) => {

  const isWebpackDevServer = process.env.WEBPACK_DEV_SERVER

  //plugins
  if (inliningCss ) {
    // Note, when this is run, we're building the server and client bundles in separate processes.
    // Thus, this plugin is not applied.
    const ReactRefreshWebpackPlugin = require('@pmmmwh/react-refresh-webpack-plugin')
    clientWebpackConfig.plugins.push(
      new ReactRefreshWebpackPlugin({
        overlay:{
          sockPort: devServer.port
        }
      })
    )
  }

  // To support TypeScript type checker on a separate process uncomment the block below and add tsconfig.json
  // to the root directory.
  // As a reference visit https://github.com/shakacode/react_on_rails_tutorial_with_ssr_and_hmr_fast_refresh/blob/master/config/webpack/development.js

  // clientWebpackConfig.plugins.push(
  //   new ForkTsCheckerWebpackPlugin({
  //     typescript: {
  //       configFile: path.resolve(__dirname, '../../tsconfig.json')
  //     },
  //     async: false
  //   })
  // )
}
module.exports = webpackConfig(developmentEnvOnly)
