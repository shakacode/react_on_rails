process.env.NODE_ENV = process.env.NODE_ENV || 'development';

const { devServer, inliningCss } = require('@rails/webpacker');

const webpackConfig = require('./webpackConfig');

const developmentEnvOnly = (clientWebpackConfig, _serverWebpackConfig) => {
  if (inliningCss) {
    // eslint-disable-next-line global-require
    const ReactRefreshWebpackPlugin = require('@pmmmwh/react-refresh-webpack-plugin');
    clientWebpackConfig.plugins.push(
      new ReactRefreshWebpackPlugin({
        overlay: {
          sockPort: devServer.port,
        },
      }),
    );
  }
};

module.exports = webpackConfig(developmentEnvOnly);
