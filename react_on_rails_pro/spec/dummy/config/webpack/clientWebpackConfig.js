const { config } = require('shakapacker');
const RSCManifestPlugin =
  config.assets_bundler === 'rspack'
    ? require('react-on-rails-rsc/RspackPlugin').RSCRspackPlugin
    : require('react-on-rails-rsc/WebpackPlugin').RSCWebpackPlugin;
const LoadablePlugin = require('@loadable/webpack-plugin');
const commonWebpackConfig = require('./commonWebpackConfig');
const rscManifestClientReferences = require('./rscManifestClientReferences');

const isHMR = process.env.HMR;

const configureClient = () => {
  const clientConfig = commonWebpackConfig();

  // server-bundle is special and should ONLY be built by the serverConfig
  // In case this entry is not deleted, a very strange "window" not found
  // error shows referring to window["webpackJsonp"]. That is because the
  // client config is going to try to load chunks.
  delete clientConfig.entry['server-bundle'];

  clientConfig.plugins.push(
    new RSCManifestPlugin({
      isServer: false,
      clientReferences: rscManifestClientReferences(),
    }),
  );

  if (!isHMR) {
    clientConfig.plugins.unshift(new LoadablePlugin({ filename: 'loadable-stats.json', writeToDisk: true }));
  }

  clientConfig.resolve.fallback = {
    fs: false,
    module: false,
    path: false,
    stream: false,
  };

  return clientConfig;
};

module.exports = configureClient;
