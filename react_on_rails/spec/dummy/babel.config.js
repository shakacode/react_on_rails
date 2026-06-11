// eslint-disable-next-line import/extensions
const defaultConfigFunc = require('shakapacker/package/babel/preset.js');

// React Compiler (issue #3866) — Babel path.
//
// The compiler is OFF by default so the standard dummy build (which uses SWC,
// see config/shakapacker.yml) and the Babel test build stay byte-identical to
// what they were before. Opt in by exporting REACT_COMPILER=1, e.g.:
//
//   REACT_COMPILER=1 RAILS_ENV=test NODE_ENV=test \
//     SHAKAPACKER_JAVASCRIPT_TRANSPILER=babel bin/shakapacker
//
// When enabled, the compiler is SCOPED via its `sources` filter to just the
// example component (client/app/startup/ReactCompilerExample.tsx) so the rest
// of the dummy app is not auto-memoized and existing tests are unaffected.
//
// Ordering: per the React docs the compiler plugin must run FIRST, before any
// other Babel plugin or preset. In Babel, plugins run before presets, and
// within the plugins array they run in order, so prepending it to `plugins`
// makes it the first transform. See docs/oss/building-features/react-compiler.md.
const reactCompilerEnabled = process.env.REACT_COMPILER === '1' || process.env.REACT_COMPILER === 'true';

// Scope the compiler to the example component only. `sources` accepts a
// predicate `(filename) => boolean`; returning true opts a file into the
// compiler. Narrowing here keeps the v1 enablement minimal and verifiable.
const reactCompilerSources = (filename) =>
  typeof filename === 'string' && filename.includes('client/app/startup/ReactCompilerExample');

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

  // React Compiler must run FIRST, ahead of every other plugin (including
  // shakapacker's @babel/plugin-transform-runtime), so it transforms the
  // original source. Prepend it only when enabled to keep the default/OFF
  // build identical to before.
  if (reactCompilerEnabled) {
    resultConfig.plugins = [
      ['babel-plugin-react-compiler', { sources: reactCompilerSources }],
      ...resultConfig.plugins,
    ];
  }

  return resultConfig;
};
