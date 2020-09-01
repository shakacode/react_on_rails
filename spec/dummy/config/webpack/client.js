const environment = require('./environment');
const merge = require('webpack-merge');

const configureClient = () => {
  // adding exposeLoader
  const exposeLoader = {
    test: require.resolve('jquery'),
    use: [{ loader: 'expose-loader', options: 'jQuery' }],
  };
  environment.loaders.insert('expose', exposeLoader, { after: 'file' });

  // adding es5Loader
  const es5Loader = {
    test: require.resolve('react'),
    use: [{ loader: 'imports-loader', options: { shim: 'es5-shim/es5-shim', sham: 'es5-shim/es5-sham' } }],
  };
  environment.loaders.insert('react', es5Loader, { after: 'sass' });

  // adding jqueryUjsLoader
  const jqueryUjsLoader = {
    test: require.resolve('jquery-ujs'),
    use: [{ loader: 'imports-loader', options: { jQuery: 'jquery' } }],
  };
  environment.loaders.insert('jquery-ujs', jqueryUjsLoader, { after: 'react' });

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
