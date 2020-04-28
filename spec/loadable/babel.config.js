// Docs to what you can get from api
// https://babeljs.io/docs/en/config-files#config-function-api
// Don't see any obvious way to pass a value from webpack.
// Note, this file would be used by babel OUTSIDE of webpack.
// Within the webpack config, babel is configured in webpack/set-module.js
module.exports = function (api) {
  // This caches the Babel config by environment.
  api.cache.using(() => process.env.NODE_ENV);

  const presets = [
    [
      '@babel/preset-env',
      {
        exclude: ['@babel/plugin-transform-typeof-symbol'],
        ignoreBrowserslistConfig: true,
        modules: false,
        targets: {
          ie: '9',
          safari: '11',
        },
        useBuiltIns: false,
      },
    ],
    [
      '@babel/preset-react',
      {
        useBuiltIns: true,
      },
    ],
  ];

  const plugins = [
    'inline-react-svg',
    [
      '@babel/plugin-proposal-class-properties',
      {
        loose: true,
      },
    ],
    [
      '@babel/plugin-proposal-object-rest-spread',
      {
        useBuiltIns: true,
      },
    ],
    '@babel/plugin-syntax-dynamic-import',
    '@babel/plugin-transform-arrow-functions',
    '@babel/plugin-transform-async-to-generator',
    '@babel/plugin-transform-destructuring',
    '@babel/plugin-transform-regenerator',
    [
      '@babel/plugin-transform-runtime',
      {
        corejs: false,
        helpers: true,
        regenerator: true,
        useESModules: true,
        // By default, the plugin assumes @babel/runtime@7.0.0. Since we use >7.0.0, better to
        // explicitly specify the version so that it can reuse the helper better
        // See https://github.com/babel/babel/issues/10261
        version: require('@babel/runtime/package.json').version,
      },
    ],
  ];

  return {
    plugins,
    presets,
    sourceType: 'unambiguous',
  };
};
