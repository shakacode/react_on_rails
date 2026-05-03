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
          // `|| 3035` falls back to Shakapacker's default if devServer.port is missing,
          // so a misconfiguration surfaces as a wrong port rather than silent NaN.
          // Note: port `0` (OS-assigned) would also fall back to 3035, but Shakapacker
          // does not use `0` as a dev server port — do not copy this pattern where `0` is valid.
          sockPort: parseInt(devServer.port, 10) || 3035,
        },
      }),
    );
  }
};

module.exports = webpackConfig(developmentEnvOnly);
