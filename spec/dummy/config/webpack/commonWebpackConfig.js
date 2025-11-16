// Common configuration applying to client and server configuration
const { generateWebpackConfig, merge } = require('shakapacker');

const baseClientWebpackConfig = generateWebpackConfig();

const webpack = require('webpack');

const aliasConfig = require('./alias');

const commonOptions = {
  resolve: {
    extensions: ['.css', '.ts', '.tsx'],
  },
};

// add sass resource loader
const sassLoaderConfig = {
  loader: 'sass-resources-loader',
  options: {
    resources: './client/app/assets/styles/app-variables.scss',
  },
};

// Process webpack rules in single pass for efficiency
baseClientWebpackConfig.module.rules.forEach((rule) => {
  if (Array.isArray(rule.use)) {
    // Add sass-resources-loader to all SCSS rules (both .scss and .module.scss)
    if (rule.test && (rule.test.test('example.scss') || rule.test.test('example.module.scss'))) {
      rule.use.push(sassLoaderConfig);
    }

    // Configure CSS Modules to use default exports (Shakapacker 9.0 compatibility)
    // Shakapacker 9.0 defaults to namedExport: true, but we use default imports
    // To restore backward compatibility with existing code using `import styles from`
    rule.use.forEach((loader) => {
      if (
        loader &&
        typeof loader === 'object' &&
        loader.loader &&
        typeof loader.loader === 'string' &&
        loader.loader.includes('css-loader') &&
        loader.options &&
        typeof loader.options === 'object' &&
        loader.options.modules &&
        typeof loader.options.modules === 'object'
      ) {
        // eslint-disable-next-line no-param-reassign
        loader.options.modules.namedExport = false;
        // eslint-disable-next-line no-param-reassign
        loader.options.modules.exportLocalsConvention = 'camelCase';
      }
    });
  }
});

// add jquery
const exposeJQuery = {
  test: require.resolve('jquery'),
  use: [{ loader: 'expose-loader', options: { exposes: ['$', 'jQuery'] } }],
};

const jqueryUjsLoader = {
  test: require.resolve('jquery-ujs'),
  use: [{ loader: 'imports-loader', options: { type: 'commonjs', imports: 'single jquery jQuery' } }],
};

baseClientWebpackConfig.plugins.push(
  new webpack.ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery',
    process: 'process/browser',
  }),
);

baseClientWebpackConfig.module.rules.push(exposeJQuery, jqueryUjsLoader);

const commonWebpackConfig = () => merge({}, baseClientWebpackConfig, commonOptions, aliasConfig);

module.exports = commonWebpackConfig;
