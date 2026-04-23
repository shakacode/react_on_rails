process.env.NODE_ENV = process.env.NODE_ENV || 'development';

const { devServer, inliningCss } = require('shakapacker');

const webpackConfig = require('./ServerClientOrBoth');

const developmentEnvOnly = (clientWebpackConfig, _serverWebpackConfig) => {
  if (inliningCss) {
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
