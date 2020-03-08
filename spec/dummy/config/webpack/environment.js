const { environment } = require('@rails/webpacker');

const sassResources = ['./client/app/assets/styles/app-variables.scss'];
const aliasConfig = require('./alias.js');
const rules = environment.loaders;
const fileLoader = rules.get('file');
const cssLoader = rules.get('css');
const sassLoader = rules.get('sass');
const babelLoader = rules.get('babel');
const ManifestPlugin = environment.plugins.get('Manifest');
const urlFileSizeCutover = 1000; // below 10k, inline, small 1K is to test file loader

// rules
sassLoader.use.push({
  loader: 'sass-resources-loader',
  options: {
    resources: sassResources,
  },
});

//adding urlLoader
const urlLoader = {
  test: /\.(jpe?g|png|gif|ico|woff)$/,
  use: {
    loader: 'url-loader',
    options: {
      limit: urlFileSizeCutover,
      // NO leading slash
      name: 'images/[name]-[hash].[ext]',
    },
  },
};
environment.loaders.insert('url', urlLoader, { before: 'file' });

// changing order of babelLoader
environment.loaders.insert('babel', babelLoader, { before: 'css' });

// add aliases to config
environment.config.merge(aliasConfig);

// modifying modules in css and sass to true,
cssLoader.use[1].options.modules = true;
sassLoader.use[1].options.modules = true;

//changing fileLoader to use proper values
fileLoader.test = /\.(ttf|eot|svg)$/;
fileLoader.use[0].options = { name: 'images/[name]-[hash].[ext]' };

// removing extra rules added by webpacker
rules.delete('nodeModules');
rules.delete('moduleCss');
rules.delete('moduleSass');

// plugins
// adding definePlugin

// manipulating manifestPlugin
ManifestPlugin.options.writeToFileEmit = true;

module.exports = environment;
