const defaultConfigFunc = require('shakapacker/package/babel/preset.js');

module.exports = (api) => {
  const resultConfig = defaultConfigFunc(api);
  const isProductionEnv = api.env('production');
  const side = api.caller((caller) => (caller && caller.ssr ? 'server' : 'client'));

  const changesOnDefault = {
    presets: [
      [
        '@babel/preset-react',
        {
          development: !isProductionEnv,
          useBuiltIns: true,
        },
      ],
    ].filter(Boolean),
    plugins: [
      [
        'macros',
        {
          useSSRComputation: {
            side,
          },
        },
      ],
      '@babel/plugin-proposal-export-default-from',
      process.env.WEBPACK_SERVE && 'react-refresh/babel',
      '@loadable/babel-plugin',
      isProductionEnv && [
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
