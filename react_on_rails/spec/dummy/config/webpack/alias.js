const { dirname, resolve } = require('path');

// Resolve from the dummy package root. The normal install uses the dummy's
// scoped React 19.2 copy for the <Activity> demo, while minimum-dependency
// conversion removes that override and lets pnpm hoist React 18 to the workspace
// root. Using Node's resolver keeps both layouts on one reachable React copy.
// TODO(#3865): simplify this once the RSC React pin lifts and the scoped dummy
// override is no longer needed.
const dummyPackageRoot = resolve(__dirname, '..', '..');
const resolveFromDummy = (specifier) => require.resolve(specifier, { paths: [dummyPackageRoot] });
const reactPackageRoot = dirname(resolveFromDummy('react/package.json'));
const reactDomPackageRoot = dirname(resolveFromDummy('react-dom/package.json'));

module.exports = {
  resolve: {
    alias: {
      Assets: resolve(__dirname, '..', '..', 'client', 'app', 'assets'),
      // Ensure a single copy of React across everything bundled here (app code
      // plus the linked workspace packages/react-on-rails) to prevent
      // "Invalid hook call" errors from duplicate React instances during SSR
      react: reactPackageRoot,
      'react/jsx-runtime': resolveFromDummy('react/jsx-runtime'),
      'react/jsx-dev-runtime': resolveFromDummy('react/jsx-dev-runtime'),
      'react-dom': reactDomPackageRoot,
      'react-dom/client': resolveFromDummy('react-dom/client'),
      'react-dom/server': resolveFromDummy('react-dom/server'),
    },
  },
};
