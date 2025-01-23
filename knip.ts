import type { KnipConfig } from 'knip';

const config: KnipConfig = {
  // ! at the end means files are used in production
  workspaces: {
    '.': {
      entry: ['node_package/src/ReactOnRails.ts!', 'node_package/src/ReactOnRails.node.ts!'],
      project: ['node_package/src/**/*.[jt]s!', 'node_package/tests/**/*.[jt]s'],
      babel: {
        config: ['node_package/babel.config.js'],
      },
      ignoreBinaries: [
        // Knip fails to detect it's declared in devDependencies
        'nps',
        // local scripts
        'node_package/scripts/.*',
      ],
      ignoreDependencies: [
        // Required for TypeScript compilation, but we don't depend on Turbolinks itself.
        '@types/turbolinks',
        // used in package-scripts.yml
        'concurrently',
        // The Knip ESLint plugin fails to detect these are transitively required by a config,
        // though we don't actually use its rules anywhere.
        'eslint-plugin-jsx-a11y',
        'eslint-plugin-react',
      ],
    },
    'spec/dummy': {
      entry: [
        'app/assets/config/manifest.js!',
        'client/app/packs/**/*.js!',
        // Not sure why this isn't detected as a dependency of client/app/packs/server-bundle.js
        'client/app/generated/server-bundle-generated.js!',
        'spec/fixtures/automated_packs_generation/**/*.js{x,}',
        'config/webpack/{production,development,test}.js',
        // Declaring this as webpack.config instead doesn't work correctly
        'config/webpack/webpack.config.js',
      ],
      project: ['**/*.{js,cjs,mjs,jsx,ts,cts,mts,tsx}!', 'config/webpack/*.js'],
      paths: {
        'Assets/*': ['client/app/assets/*'],
      },
      ignoreBinaries: [
        // Has to be installed globally
        'yalc',
        // Local binaries
        'bin/.*',
      ],
      ignoreDependencies: [
        // There's no ReScript plugin for Knip
        '@rescript/react',
        // The Babel plugin fails to detect it
        'babel-plugin-transform-react-remove-prop-types',
        // Temporary!
        '.*',
      ],
    },
  },
};

export default config;
