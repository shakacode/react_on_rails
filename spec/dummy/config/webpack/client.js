const environment = require('./environment');
const devBuild = process.env.NODE_ENV === 'development';

if (!module.hot && devBuild) {
  environment.loaders
    .get('sass')
    .use.find((item) => item.loader === 'sass-loader').options.sourceMapContents = false;
}

//adding reactHotReload
const reactHotReload = {
  test: /\.(js|jsx)$/,
  use: 'react-hot-loader/webpack',
  include: /node_modules/,
};
environment.loaders.insert('reactHotReload', reactHotReload, { after: 'babel' });

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

module.exports = environment;
