// The source code including full typescript support is available at:
// https://github.com/shakacode/react-on-rails-demo-ssr-hmr/blob/master/config/webpack/development.js

const { devServer, inliningCss } = require('shakapacker');

const webpackConfig = require('./webpackConfig');

const developmentEnvOnly = (clientWebpackConfig, _serverWebpackConfig) => {
  // plugins
  if (inliningCss) {
    // Note, when this is run, we're building the server and client bundles in separate processes.
    // Thus, this plugin is not applied to the server bundle.

    // eslint-disable-next-line global-require
    const ReactRefreshWebpackPlugin = require('@pmmmwh/react-refresh-webpack-plugin');
    clientWebpackConfig.plugins.push(
      new ReactRefreshWebpackPlugin({
        overlay: {
          // bin/dev sets SHAKAPACKER_DEV_SERVER_PORT as a string, which Shakapacker
          // surfaces unchanged on devServer.port. The plugin schema requires a number.
          sockPort: Number(devServer.port),
        },
      }),
    );
  }
};

module.exports = webpackConfig(developmentEnvOnly);
