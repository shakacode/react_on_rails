const { generateWebpackConfig, merge } = require('shakapacker');
const webpack = require('webpack');

const sassResources = ['./client/app/assets/styles/app-variables.scss'];
const aliasConfig = require('./alias');

const commonOptions = {
  resolve: {
    extensions: ['.css', '.ts', '.tsx'],
  },
};

const isHMR = process.env.HMR;

// For details on the pros and cons of inlining images:
// https://developers.google.com/web/fundamentals/design-and-ux/responsive/images
// https://survivejs.com/webpack/loading/images/
// Normally below 1k, inline. We're making the example bigger to show a both inlined and non-inlined images

// rules
const sassLoaderConfig = {
  loader: 'sass-resources-loader',
  options: {
    resources: sassResources,
  },
};

const baseClientWebpackConfig = generateWebpackConfig();

// Add sass-resources-loader to all SCSS rules (both .scss and .module.scss)
baseClientWebpackConfig.module.rules.forEach((rule) => {
  if (
    Array.isArray(rule.use) &&
    rule.test &&
    (rule.test.test('example.scss') || rule.test.test('example.module.scss'))
  ) {
    rule.use.push(sassLoaderConfig);
  }
});

if (isHMR) {
  baseClientWebpackConfig.plugins.push(
    new webpack.NormalModuleReplacementPlugin(/(.*)\.imports-loadable(\.jsx)?/, (resource) => {
      // eslint-disable-next-line no-param-reassign
      resource.request = resource.request.replace(/imports-loadable/, 'imports-hmr');
      return resource.request;
    }),
  );
}

const commonWebpackConfig = () => {
  const config = merge({}, baseClientWebpackConfig, commonOptions, aliasConfig);

  // Fix CSS modules for Shakapacker 9.x compatibility
  // Shakapacker 9 defaults to namedExport: true, but our code uses default imports
  // Override to use the old behavior for backward compatibility
  config.module.rules.forEach((rule) => {
    if (rule.test && (rule.test.test('example.module.scss') || rule.test.test('example.module.css'))) {
      if (Array.isArray(rule.use)) {
        rule.use.forEach((loader) => {
          if (
            loader.loader &&
            loader.loader.includes('css-loader') &&
            loader.options &&
            loader.options.modules
          ) {
            // Disable named exports to support default imports
            // eslint-disable-next-line no-param-reassign
            loader.options.modules.namedExport = false;
            // eslint-disable-next-line no-param-reassign
            loader.options.modules.exportLocalsConvention = 'camelCase';
          }
        });
      }
    }
  });

  return config;
};

module.exports = commonWebpackConfig;
