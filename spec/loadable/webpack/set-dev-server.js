const _ = require('lodash/fp');
const { config, devServer: webpackerDevServer } = require('@rails/webpacker');

// https://webpack.js.org/guides/hot-module-replacement/#enabling-hmr
function setDevServer(builderConfig, webpackConfig) {
  if (!builderConfig.devServer) {
    return webpackConfig;
  }

  // See webpacker/package/environments/development.js
  const devServer = {
    clientLogLevel: 'none',
    compress: webpackerDevServer.compress,
    quiet: webpackerDevServer.quiet,
    disableHostCheck: webpackerDevServer.disable_host_check,
    host: webpackerDevServer.host,
    port: webpackerDevServer.port,
    https: webpackerDevServer.https,
    hot: webpackerDevServer.hmr,
    contentBase: config.outputPath,
    inline: webpackerDevServer.inline,
    useLocalIp: webpackerDevServer.use_local_ip,
    publicPath: config.publicPath,
    historyApiFallback: {
      disableDotRule: true,
    },
    headers: webpackerDevServer.headers,
    overlay: webpackerDevServer.overlay,
    stats: {
      entrypoints: false,
      errorDetails: true,
      modules: false,
      moduleTrace: false,
    },
    watchOptions: webpackerDevServer.watch_options,
  };

  return _.set('devServer', devServer, webpackConfig);
}

module.exports = _.curry(setDevServer);
