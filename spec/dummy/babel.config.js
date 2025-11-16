// eslint-disable-next-line import/extensions
const defaultConfigFunc = require('shakapacker/package/babel/preset.js');

module.exports = function createBabelConfig(api) {
  const resultConfig = defaultConfigFunc(api);
  const isProductionEnv = api.env('production');
  const isDevelopmentEnv = api.env('development');

  const changesOnDefault = {
    presets: [
      [
        '@babel/preset-react',
        {
          development: !isProductionEnv,
          runtime: 'automatic',
          useBuiltIns: true,
        },
      ],
    ].filter(Boolean),
    plugins: [
      process.env.WEBPACK_SERVE && 'react-refresh/babel',
      !isDevelopmentEnv && [
        'babel-plugin-transform-react-remove-prop-types',
        {
          removeImport: true,
        },
      ],
    ].filter(Boolean),
  };

  resultConfig.presets = [...resultConfig.presets, ...changesOnDefault.presets];
  resultConfig.plugins = [...resultConfig.plugins, ...changesOnDefault.plugins];

  return resultConfig;
};
