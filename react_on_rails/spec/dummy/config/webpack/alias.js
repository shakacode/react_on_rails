const { resolve } = require('path');

// The dummy app's own node_modules. This app is pinned to React 19.2 (for the
// <Activity> demo, issue #3883) via the scoped `react_on_rails>react` override
// in the workspace root package.json, while the rest of the monorepo stays on
// the workspace-wide React pin. Aliasing to the dummy's own copy keeps the
// bundles on 19.2 instead of the root workspace copy.
// TODO(#3865): revert this alias to the workspace root once the RSC React pin
// lifts and the scoped dummy override is no longer needed.
const dummyNodeModules = resolve(__dirname, '..', '..', 'node_modules');

module.exports = {
  resolve: {
    alias: {
      Assets: resolve(__dirname, '..', '..', 'client', 'app', 'assets'),
      // Ensure a single copy of React across everything bundled here (app code
      // plus the linked workspace packages/react-on-rails) to prevent
      // "Invalid hook call" errors from duplicate React instances during SSR
      react: resolve(dummyNodeModules, 'react'),
      'react/jsx-runtime': resolve(dummyNodeModules, 'react', 'jsx-runtime'),
      'react/jsx-dev-runtime': resolve(dummyNodeModules, 'react', 'jsx-dev-runtime'),
      'react-dom': resolve(dummyNodeModules, 'react-dom'),
      'react-dom/client': resolve(dummyNodeModules, 'react-dom', 'client'),
      'react-dom/server': resolve(dummyNodeModules, 'react-dom', 'server'),
    },
  },
};
