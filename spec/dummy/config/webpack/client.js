const environment = require('./environment');
const devBuild = process.env.NODE_ENV === 'development';
const isHMR = process.env.WEBPACK_DEV_SERVER === 'TRUE';
const ReactRefreshWebpackPlugin = require('@pmmmwh/react-refresh-webpack-plugin');

if (devBuild && !isHMR) {
  environment.loaders
    .get('sass')
    .use.find((item) => item.loader === 'sass-loader').options.sourceMapContents = false;
}

//adding exposeLoader
const exposeLoader = {
  test: require.resolve('jquery'),
  use: [{ loader: 'expose-loader', options: 'jQuery' }],
};
environment.loaders.insert('expose', exposeLoader, { after: 'file' });

//adding es5Loader
const es5Loader = {
  test: require.resolve('react'),
  use: [{ loader: 'imports-loader', options: { shim: 'es5-shim/es5-shim', sham: 'es5-shim/es5-sham' } }],
};
environment.loaders.insert('react', es5Loader, { after: 'sass' });

//adding jqueryUjsLoader
const jqueryUjsLoader = {
  test: require.resolve('jquery-ujs'),
  use: [{ loader: 'imports-loader', options: { jQuery: 'jquery' } }],
};
environment.loaders.insert('jquery-ujs', jqueryUjsLoader, { after: 'react' });

if (devBuild && isHMR) {
  environment.plugins.insert('ReactRefreshWebpackPlugin', new ReactRefreshWebpackPlugin());
}

module.exports = environment;
