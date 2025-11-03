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
const scssConfigIndex = baseClientWebpackConfig.module.rules.findIndex((config) =>
  '.scss'.match(config.test),
);
if (scssConfigIndex !== -1 && baseClientWebpackConfig.module.rules[scssConfigIndex]?.use) {
  baseClientWebpackConfig.module.rules[scssConfigIndex].use.push(sassLoaderConfig);
}

if (isHMR) {
  baseClientWebpackConfig.plugins.push(
    new webpack.NormalModuleReplacementPlugin(/(.*)\.imports-loadable(\.jsx)?/, (resource) => {
      // eslint-disable-next-line no-param-reassign
      resource.request = resource.request.replace(/imports-loadable/, 'imports-hmr');
      return resource.request;
    }),
  );
}

const commonWebpackConfig = () => merge({}, baseClientWebpackConfig, commonOptions, aliasConfig);

module.exports = commonWebpackConfig;
