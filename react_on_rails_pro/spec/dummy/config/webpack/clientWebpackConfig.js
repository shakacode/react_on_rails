const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
const LoadablePlugin = require('@loadable/webpack-plugin');
const commonWebpackConfig = require('./commonWebpackConfig');

const isHMR = process.env.HMR;

const configureClient = () => {
  const clientConfig = commonWebpackConfig();

  // server-bundle is special and should ONLY be built by the serverConfig
  // In case this entry is not deleted, a very strange "window" not found
  // error shows referring to window["webpackJsonp"]. That is because the
  // client config is going to try to load chunks.
  delete clientConfig.entry['server-bundle'];

  clientConfig.plugins.push(
    new RSCWebpackPlugin({
      isServer: false,
      // Limit client reference discovery to the app source directory to prevent
      // the plugin from traversing into node_modules/ (which with pnpm workspace
      // symlinks exposes .tsx source files that lack a configured loader)
      clientReferences: [{ directory: './client/app', recursive: true, include: /\.(js|ts|jsx|tsx)$/ }],
    }),
  );

  if (!isHMR) {
    clientConfig.plugins.unshift(new LoadablePlugin({ filename: 'loadable-stats.json', writeToDisk: true }));
  }

  clientConfig.resolve.fallback = {
    fs: false,
    path: false,
    stream: false,
  };

  return clientConfig;
};

module.exports = configureClient;
