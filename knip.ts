import type { KnipConfig } from 'knip';

const config: KnipConfig = {
  // ! at the end means files are used in production
  workspaces: {
    // Root workspace - manages the monorepo and global tooling
    '.': {
      entry: ['eslint.config.ts', 'jest.config.base.js'],
      project: ['*.{js,mjs,ts}'],
      ignoreBinaries: [
        // Has to be installed globally
        'yalc',
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
        'jest-junit',
        // This is an optional peer dependency because users without RSC don't need it
        // but Knip doesn't like such dependencies to be referenced directly in code
        'react-on-rails-rsc',
        // SWC transpiler dependencies used by Shakapacker in dummy apps
        '@swc/core',
        'swc-loader',
      ],
    },

    // React on Rails core package workspace
    'packages/react-on-rails': {
      entry: [
        'src/ReactOnRails.full.ts!',
        'src/ReactOnRails.client.ts!',
        'src/base/full.rsc.ts!',
        'src/context.ts!',
      ],
      project: ['src/**/*.[jt]s{x,}!', 'tests/**/*.[jt]s{x,}', '!lib/**'],
      ignore: [
        // Jest setup and test utilities - not detected by Jest plugin in workspace setup
        'tests/jest.setup.js',
        // Build output directories that should be ignored
        'lib/**',
      ],
    },

    // React on Rails Pro Node Renderer package workspace
    'packages/react-on-rails-pro-node-renderer': {
      entry: [
        'src/ReactOnRailsProNodeRenderer.ts!',
        'src/default-node-renderer.ts!',
        'src/integrations/*.ts!',
      ],
      project: ['src/**/*.[jt]s{x,}!', 'tests/**/*.[jt]s{x,}', '!lib/**'],
      ignore: [
        // Build output directories that should be ignored
        'lib/**',
        // Test fixtures
        'tests/fixtures/**',
        // Test helper utilities
        'tests/helper.ts',
        'tests/httpRequestUtils.ts',
      ],
      ignoreDependencies: [
        // Optional dependencies used in integrations
        '@honeybadger-io/js',
        '@sentry/*',
        // Jest reporter used in CI
        'jest-junit',
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
        'tests/utils/removeRSCStackFromAllChunks.ts',
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
    'react_on_rails/spec/dummy': {
      entry: [
        'app/assets/config/manifest.js!',
        'client/app/packs/**/*.js!',
        // Not sure why this isn't detected as a dependency of client/app/packs/server-bundle.js
        'client/app/generated/server-bundle-generated.js!',
        'config/webpack/{production,development,test}.js',
        // Declaring this as webpack.config instead doesn't work correctly
        'config/webpack/webpack.config.js',
        // SWC configuration for Shakapacker
        'config/swc.config.js',
        // Playwright E2E test configuration and tests
        'e2e/playwright.config.js',
        'e2e/playwright/e2e/**/*.spec.js',
        // CI workflow files that reference package.json scripts
        '../../../.github/workflows/playwright.yml',
      ],
      ignore: [
        '**/app-react16/**/*',
        // Bundled gems should not be analyzed by Knip
        'vendor/bundle/**',
        // Test files that shouldn't be treated as entry points
        'tests/**',
        'spec/**',
        // Config files that require dependencies not in workspace root
        'babel.config.js',
        // Playwright support files and helpers - generated by cypress-on-rails gem
        'e2e/playwright/support/**',
        // Components and files used dynamically by React on Rails (registered at runtime)
        'client/app/actions/**',
        'client/app/components/**',
        'client/app/routes/**',
        'client/app/startup/**',
        'client/app/store/**',
        // ReScript entry files that import compiled .res.js files (compiled at build time)
        'client/app/packs/rescript-components.js',
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
        // Required by @babel/plugin-transform-runtime for polyfills
        '@babel/runtime',
        // Used in webpack server config to filter out MiniCssExtractPlugin
        'mini-css-extract-plugin',
        // This one is weird. It's long-deprecated and shouldn't be necessary.
        // Probably need to update the Webpack config.
        'node-libs-browser',
        // The below dependencies are not detected by the Webpack plugin
        // due to the config issue.
        'expose-loader',
        'file-loader',
        'imports-loader',
        'null-loader',
        'sass-resources-loader',
        'style-loader',
        'url-loader',
        // Used in ignored client/app components (dynamically loaded by React on Rails)
        'create-react-class',
        'react-helmet',
        '@types/react-helmet',
        'react-redux',
        'react-router-dom',
        // Transitive dependency of shakapacker but listed as direct dependency
        'webpack-merge',
      ],
    },
  },
  ignoreExportsUsedInFile: true,
};

export default config;
