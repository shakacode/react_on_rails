import type { KnipConfig } from 'knip';

const config: KnipConfig = {
  // ! at the end means files are used in production
  workspaces: {
    // Root workspace - manages the monorepo and global tooling
    '.': {
      entry: ['eslint.config.ts'],
      project: ['*.{js,mjs,ts}'],
      ignoreBinaries: [
        // Has to be installed globally
        'yalc',
        'nps',
        // Pro package binaries used in Pro workflows
        'playwright',
        'e2e-test',
      ],
      ignore: ['react_on_rails_pro/**'],
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
        // used by Jest
        'jsdom',
        // This is an optional peer dependency because users without RSC don't need it
        // but Knip doesn't like such dependencies to be referenced directly in code
        'react-on-rails-rsc',
      ],
    },

    // React on Rails core package workspace
    'packages/react-on-rails': {
      entry: ['src/ReactOnRails.full.ts!', 'src/ReactOnRails.client.ts!', 'src/base/full.rsc.ts!'],
      project: ['src/**/*.[jt]s{x,}!', 'tests/**/*.[jt]s{x,}', '!lib/**'],
      ignore: [
        // Jest setup and test utilities - not detected by Jest plugin in workspace setup
        'tests/jest.setup.js',
        // Build output directories that should be ignored
        'lib/**',
      ],
    },

    // React on Rails Pro package workspace
    'packages/react-on-rails-pro': {
      entry: [
        'src/ReactOnRails.node.ts!',
        'src/ReactOnRails.full.ts!',
        'src/ReactOnRails.client.ts!',
        'src/index.ts!',
        'src/ReactOnRailsRSC.ts!',
        'src/registerServerComponent/client.tsx!',
        'src/registerServerComponent/server.tsx!',
        'src/registerServerComponent/server.rsc.ts!',
        'src/wrapServerComponentRenderer/server.tsx!',
        'src/wrapServerComponentRenderer/server.rsc.tsx!',
        'src/RSCRoute.tsx!',
        'src/ServerComponentFetchError.ts!',
        'src/getReactServerComponent.server.ts!',
        'src/transformRSCNodeStream.ts!',
      ],
      project: ['src/**/*.[jt]s{x,}!', 'tests/**/*.[jt]s{x,}', '!lib/**'],
      ignore: [
        'tests/emptyForTesting.js',
        // Jest setup and test utilities - not detected by Jest plugin in workspace setup
        'tests/jest.setup.js',
        // Build output directories that should be ignored
        'lib/**',
        // Pro features exported for external consumption
        'src/streamServerRenderedReactComponent.ts:transformRenderStreamChunksToResultObject',
        'src/streamServerRenderedReactComponent.ts:streamServerRenderedComponent',
        'src/ServerComponentFetchError.ts:isServerComponentFetchError',
        'src/RSCRoute.tsx:RSCRouteProps',
        'src/streamServerRenderedReactComponent.ts:StreamingTrackers',
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
      ignore: ['**/app-react16/**/*'],
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
