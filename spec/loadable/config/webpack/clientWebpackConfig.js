const webpack = require('webpack');
const commonWebpackConfig = require('./commonWebpackConfig');
const LoadablePlugin = require('@loadable/webpack-plugin');

const isHMR = process.env.HMR;

const configureClient = () => {
  const clientConfig = commonWebpackConfig();

  // server-bundle is special and should ONLY be built by the serverConfig
  // In case this entry is not deleted, a very strange "window" not found
  // error shows referring to window["webpackJsonp"]. That is because the
  // client config is going to try to load chunks.
  delete clientConfig.entry['server-bundle'];

  if (!isHMR) {
    clientConfig.plugins.unshift(new LoadablePlugin({ filename: 'loadable-stats.json', writeToDisk: true }));
  } else {
    clientConfig.plugins.unshift(
      new webpack.NormalModuleReplacementPlugin(/(.*)\.imports-loadable(\.jsx)?/, (resource) => {
        /* eslint-disable no-param-reassign */
        resource.request = resource.request.replace(/imports-loadable/, 'imports-hmr');
        /* eslint-enable no-param-reassign */
        return resource.request;
      }),
    );
  }

  return clientConfig;
};

module.exports = configureClient;
