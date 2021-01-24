const environment = require('./environment');
const { merge } = require('webpack-merge');

const configureClient = () => {
  const clientConfigObject = environment.toWebpackConfig();
  // Copy the object using merge b/c the clientConfigObject is non-stop mutable
  // After calling toWebpackConfig, and then modifying the resulting object,
  // another call to `toWebpackConfig` on this same environment will overwrite
  // the next line.
  const clientConfig = merge({}, clientConfigObject);

  // server-bundle is special and should ONLY be built by the serverConfig
  // In case this entry is not deleted, a very strange "window" not found
  // error shows referring to window["webpackJsonp"]. That is because the
  // client config is going to try to load chunks.
  delete clientConfig.entry['server-bundle'];

  return clientConfig;
};

module.exports = configureClient;
