import type { KnipConfig } from 'knip';

const config: KnipConfig = {
  // ! at the end means files are used in production
  workspaces: {
    '.': {
      entry: [
        'node_package/src/ReactOnRails.node.ts!',
        'node_package/src/ReactOnRailsRSC.ts!',
        'node_package/src/registerServerComponent/client.ts!',
        'node_package/src/registerServerComponent/server.ts!',
        'node_package/src/RSCClientRoot.ts!',
        'eslint.config.ts',
      ],
      project: ['node_package/src/**/*.[jt]s{x,}!', 'node_package/tests/**/*.[jt]s{x,}'],
      babel: {
        config: ['node_package/babel.config.js'],
      },
      ignore: ['node_package/tests/emptyForTesting.js'],
      ignoreBinaries: [
        // Knip fails to detect it's declared in devDependencies
        'nps',
        // local scripts
        'node_package/scripts/.*',
      ],
      ignoreDependencies: [
        // Required for TypeScript compilation, but we don't depend on Turbolinks itself.
        '@types/turbolinks',
        // The Knip ESLint plugin fails to detect these are transitively required by a config,
        // though we don't actually use its rules anywhere.
        '@babel/eslint-parser',
        '@babel/preset-react',
        'eslint-config-shakacode',
        'eslint-import-resolver-alias',
        'eslint-plugin-import',
        'eslint-plugin-jsx-a11y',
        'eslint-plugin-react',
        'eslint-plugin-react-hooks',
        // These are used as transitive dependencies and missing from package.json
        '@eslint/eslintrc',
        '@eslint/js',
        // Used in CI
        '@arethetypeswrong/cli',
        // used by Jest
        'jsdom',
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
        // Knip thinks it can be a devDependency, but it's supposed to be in dependencies.
        '@babel/runtime',
        // There's no ReScript plugin for Knip
        '@rescript/react',
        // The Babel plugin fails to detect it
        'babel-plugin-transform-react-remove-prop-types',
        // This one is weird. It's long-deprecated and shouldn't be necessary.
        // Probably need to update the Webpack config.
        'node-libs-browser',
        // The below dependencies are not detected by the Webpack plugin
        // due to the config issue.
        'css-loader',
        'expose-loader',
        'file-loader',
        'imports-loader',
        'mini-css-extract-plugin',
        'null-loader',
        'sass',
        'sass-loader',
        'sass-resources-loader',
        'style-loader',
        'url-loader',
      ],
    },
  },
};

export default config;
