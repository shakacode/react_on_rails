const { environment } = require('@rails/webpacker');
const { resolve } = require('path');
const webpack = require('webpack');

const sassResources = ['./client/app/assets/styles/app-variables.scss'];
const aliasConfig = require('./alias.js');
const rules = environment.loaders;
const fileLoader = rules.get('file');
const ManifestPlugin = environment.plugins.get('Manifest');

// For details on the pros and cons of inlining images:
// https://developers.google.com/web/fundamentals/design-and-ux/responsive/images
// https://survivejs.com/webpack/loading/images/
// Normally below 1k, inline. We're making the example bigger to show a both inlined and non-inlined images
const urlFileSizeCutover = 10000;

const urlLoaderOptions = Object.assign(
  { limit: urlFileSizeCutover, esModule: false },
  fileLoader.use[0].options,
);
//adding urlLoader
const urlLoader = {
  test: fileLoader.test,
  use: {
    loader: 'url-loader',
    options: urlLoaderOptions,
  },
};

rules.insert('url', urlLoader, { before: 'file' });
rules.delete('file');

// rules
const sassLoaderConfig = {
  loader: 'sass-resources-loader',
  options: {
    resources: sassResources,
  },
};

function addSassResourcesLoader(ruleName) {
  const sassLoaders = rules.get(ruleName).use;
  sassLoaders.push(sassLoaderConfig);
}

addSassResourcesLoader('sass');
addSassResourcesLoader('moduleSass');

const root = resolve(__dirname, '../../client/app');
const resolveUrlLoader = {
  loader: 'resolve-url-loader',
  options: {
    root,
  },
};

const addResolveUrlLoader = (ruleName) => {
  const ruleLoaders = rules.get(ruleName).use;
  const insertPos = ruleLoaders.findIndex((item) => item.loader === 'sass-loader');
  ruleLoaders.splice(insertPos, 0, resolveUrlLoader);
};

addResolveUrlLoader('sass');
addResolveUrlLoader('moduleSass');

environment.splitChunks();

// add aliases to config
environment.config.merge(aliasConfig);

environment.plugins.append(
  'Provide',
  new webpack.ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery',
  }),
);

environment.loaders.append('expose', {
  test: require.resolve('jquery'),
  use: [{ loader: 'expose-loader', options: { exposes: ['$', 'jQuery'] } }],
});

// adding jqueryUjsLoader
const jqueryUjsLoader = {
  test: require.resolve('jquery-ujs'),
  use: [{ loader: 'imports-loader', options: { type: 'commonjs', imports: 'single jquery jQuery' } }],
};
environment.loaders.append('jquery-ujs', jqueryUjsLoader);

module.exports = environment;
