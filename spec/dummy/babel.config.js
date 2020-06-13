module.exports = function (api) {
  const validEnv = ['development', 'test', 'production'];
  const env = api.env();
  api.cache.using(() => env);
  const isDevelopmentEnv = api.env('development');
  const isProductionEnv = api.env('production');
  const isTestEnv = api.env('test');
  const isHMR = process.env.WEBPACK_DEV_SERVER;

  if (!validEnv.includes(env)) {
    throw new Error(
      'Please specify a valid `NODE_ENV` or ' +
        '`BABEL_ENV` environment variables. Valid values are "development", ' +
        '"test", and "production". Instead, received: ' +
        JSON.stringify(env) +
        '.',
    );
  }

  return {
    presets: [
      // Let's comment out and document how this file and the other config files
      // differ from https://github.com/rails/webpacker/blob/master/lib/install/config/babel.config.js
      // and the other files in that are installed by default.

      // We may need differences in testEnv for running jest tests
      // isTestEnv && [
      //   require('@babel/preset-env').default,
      //   {
      //     targets: {
      //       node: 'current'
      //     }
      //   }
      // ],
      // (isProductionEnv || isDevelopmentEnv) &&
      [
        require('@babel/preset-env').default,
        {
          // OK to support ES5
          // https://babeljs.io/docs/en/babel-preset-env#forcealltransforms
          forceAllTransforms: true,
          // OK to include polyfills globally, just once
          // https://babeljs.io/docs/en/babel-preset-env#usebuiltins-entry
          useBuiltIns: 'entry',
          // OK to not use ES6 modules since we want to support ES5
          // https://babeljs.io/docs/en/babel-preset-env#modules
          modules: false,
          // No idea on this one.
          // Suggestion for performance from create-react-app
          // https://github.com/facebook/create-react-app/issues/5277
          exclude: ['transform-typeof-symbol'],
        },
      ],
      [
        require('@babel/preset-react').default,
        {
          development: isDevelopmentEnv || isTestEnv,
          useBuiltIns: true,
        },
      ],
    ].filter(Boolean),
    plugins: [
      [
        require('babel-plugin-module-resolver').default,
        {
          root: ['./client/app/assets/images'],
          alias: {
            images: './images',
          },
        },
      ],
      isDevelopmentEnv && isHMR && require('react-refresh/babel'),
      require('babel-plugin-macros'),
      require('@babel/plugin-syntax-dynamic-import').default,

      // Hard to say why this would be needed.
      // CRA has this:
      // https://github.com/facebook/create-react-app/pull/4984
      // isTestEnv && require('babel-plugin-dynamic-import-node'),
      require('@babel/plugin-transform-destructuring').default,
      [
        require('@babel/plugin-proposal-class-properties').default,
        {
          loose: true,
        },
      ],
      [
        require('@babel/plugin-proposal-object-rest-spread').default,
        {
          useBuiltIns: true,
        },
      ],
      [
        require('@babel/plugin-transform-runtime').default,
        {
          helpers: false,
          regenerator: true,
        },
      ],
      [
        require('@babel/plugin-transform-regenerator').default,
        {
          async: false,
        },
      ],
      isProductionEnv && [
        require('babel-plugin-transform-react-remove-prop-types').default,
        {
          removeImport: true,
        },
      ],
    ].filter(Boolean),
  };
};
