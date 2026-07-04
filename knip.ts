import type { KnipConfig } from 'knip';

const config: KnipConfig = {
  // ! at the end means files are used in production
  workspaces: {
    // Root workspace - manages the monorepo and global tooling
    '.': {
      entry: [
        'eslint.config.ts',
        'jest.config.base.js',
        'benchmarks/k6.ts',
        '.github/workflows/shakaperf-release-gates.yml',
        'test/shakaperf/**/*.ts',
        // Custom ESLint rule tests are run standalone via `pnpm run test:eslint-rules`
        // (plain `node`, no importer), so knip needs them declared as entry points.
        'eslint-rules/**/*.test.cjs',
      ],
      project: ['*.{js,mjs,ts}', 'test/shakaperf/**/*.ts', 'eslint-rules/**/*.cjs'],
      ignoreBinaries: [
        // Pro package binaries used in Pro workflows
        'playwright',
        'e2e-test',
        // pnpm script inside react_on_rails_pro/spec/dummy (that tree is excluded from
        // knip via the react_on_rails_pro/** ignore below); invoked by pro-integration-tests.yml.
        'e2e-test:rsc',
        // GitHub CLI, preinstalled on GitHub Actions runners; invoked by update-llms-full.yml.
        'gh',
        // Task runner invoked by the `start`/`lint` package.json scripts. `knip --production`
        // strips this devDependency and would otherwise report `nps` as an unlisted binary.
        'nps',
        // Local binaries
        'bin/.*',
      ],
      ignore: ['react_on_rails_pro/**', 'react_on_rails/vendor/**'],
      ignoreDependencies: [
        // Required for TypeScript compilation, but we don't depend on Turbolinks itself.
        '@types/turbolinks',
        // The Knip ESLint plugin fails to detect these are transitively required by a config,
        // though we don't actually use its rules anywhere.
        '@babel/eslint-parser',
        '@babel/preset-react',
        'eslint-config-shakacode',
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
        // Optional peer dependency: only apps using the TanStack Router adapter need it.
        // It is pinned as a devDependency in packages/react-on-rails-pro for tests,
        // but Knip still flags optional peers referenced in code.
        '@tanstack/react-router',
        // SWC transpiler dependencies used by Shakapacker in dummy apps
        '@swc/core',
        'swc-loader',
        // Used by the release gate workflow via `pnpm exec shaka-perf`; Knip does
        // not detect that CLI usage from the GitHub Actions shell command.
        'shaka-perf',
      ],
    },

    // Create React on Rails app package workspace
    'packages/create-react-on-rails-app': {
      // src/utils.ts is a production module: index.ts imports its shared `pc`
      // color instance, and utils.ts is where `picocolors` is imported. In
      // --production mode knip does not trace a dependency through that value
      // re-export, so utils.ts must be listed as a production entry for
      // `picocolors` to be counted as used (otherwise it is falsely flagged
      // as an unused dependency).
      //
      // Tradeoff: listing utils.ts as an entry marks ALL of its exports
      // (execLiveArgs, getCommandVersion, logStep, ...) as always-used roots,
      // so `knip --production` will not flag them if one later becomes dead.
      // Accepted here because utils.ts is a small, fully-consumed helper module;
      // revisit if it grows or accumulates unused exports.
      entry: ['bin/create-react-on-rails-app.js!', 'src/index.ts!', 'src/utils.ts!'],
      project: ['src/**/*.ts', 'tests/**/*.ts'],
      ignore: ['lib/**', 'node_modules/**'],
    },

    // React on Rails core package workspace
    'packages/react-on-rails': {
      entry: [
        'src/ReactOnRails.full.ts!',
        'src/ReactOnRails.client.ts!',
        'src/base/full.rsc.ts!',
        'src/capabilities/ssr.rsc.ts!',
        'src/context.ts!',
      ],
      project: ['src/**/*.[jt]s{x,}!', 'tests/**/*.[jt]s{x,}', '!lib/**'],
      ignore: [
        // Jest setup and test utilities - not detected by Jest plugin in workspace setup
        'tests/jest.setup.js',
        // Build output directories that should be ignored
        'lib/**',
      ],
      ignoreDependencies: [],
    },

    // React on Rails Pro Node Renderer package workspace
    'packages/react-on-rails-pro-node-renderer': {
      entry: [
        'src/ReactOnRailsProNodeRenderer.ts!',
        'src/default-node-renderer.ts!',
        'src/integrations/*.ts!',
        // Export disableHttp2 for test utilities
        'src/worker.ts!',
        // License validator: reset() is used in tests, getLicenseStatus/LicenseStatus imported by master.ts
        'src/shared/licenseValidator.ts!',
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
        'src/testUtils/opentelemetry.ts',
      ],
      ignoreDependencies: [
        // Optional dependencies used in integrations
        '@honeybadger-io/js',
        '@fastify/otel',
        '@opentelemetry/api',
        '@opentelemetry/exporter-trace-otlp-http',
        '@opentelemetry/instrumentation',
        '@opentelemetry/instrumentation-http',
        '@opentelemetry/resources',
        '@opentelemetry/sdk-trace-base',
        '@opentelemetry/sdk-trace-node',
        '@opentelemetry/semantic-conventions',
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
        'src/tanstack-router.ts!',
        'src/cache/index.stub.ts!',
        'src/registerDefaultRSCProvider.client.tsx!',
      ],
      ignoreDependencies: [
        // Optional peer dependency: only apps using the Redis cache handler need it.
        // Knip flags optional peers referenced in code via lazy require().
        'ioredis',
      ],
      project: ['src/**/*.[jt]s{x,}!', 'tests/**/*.[jt]s{x,}', '!lib/**'],
      ignore: [
        'tests/emptyForTesting.js',
        // Jest setup and test utilities - not detected by Jest plugin in workspace setup
        'tests/jest.setup.js',
        'tests/utils/removeRSCStackFromAllChunks.ts',
        // Test fixtures referenced dynamically (e.g. via webpack NormalModuleReplacementPlugin)
        'tests/fixtures/**',
        // Build output directories that should be ignored
        'lib/**',
      ],
    },
    'react_on_rails/spec/dummy': {
      entry: [
        'app/assets/config/manifest.js!',
        'client/app/packs/**/*.{js,jsx,ts,tsx}!',
        // Not sure why this isn't detected as a dependency of client/app/packs/server-bundle.ts.
        // The file is produced by `rake react_on_rails:generate_packs` (run in CI before knip),
        // so knip only reports this entry as an unmatched pattern on a fresh checkout without
        // generated packs. Keep it: the entry does real work in CI where the file exists.
        'client/app/generated/server-bundle-generated.js!',
        'config/webpack/{production,development,test}.js',
        // Declaring this as webpack.config instead doesn't work correctly
        'config/webpack/webpack.config.js',
        'config/rspack/rspack.config.js',
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
        'client/app/packs/rescript-components.ts',
      ],
      project: ['**/*.{js,cjs,mjs,jsx,ts,cts,mts,tsx}!', 'config/webpack/*.js'],
      paths: {
        'Assets/*': ['client/app/assets/*'],
      },
      ignoreBinaries: [
        // Local binaries
        'bin/.*',
      ],
      ignoreDependencies: [
        // There's no ReScript plugin for Knip
        '@rescript/react',
        // The Babel plugin fails to detect it
        'babel-plugin-transform-react-remove-prop-types',
        // Required by @babel/plugin-transform-runtime for polyfills (used by webpack).
        // Only flagged as unused by `knip --production`, which strips the dev-only usage.
        '@babel/runtime',
        // Used in webpack server config for CSS extraction.
        // Only flagged as unused by `knip --production`, which strips the dev-only usage.
        'mini-css-extract-plugin',
        // Webpack config merge helper is used in the dummy app config, but not detected reliably by Knip.
        'webpack-merge',
        // Shakapacker adapter package is selected by the dummy app's package/config tooling, not imported directly.
        'shakapacker-webpack',
        // Used by dynamically registered dummy app components, which are intentionally ignored above.
        '@dr.pogodin/react-helmet',
        'create-react-class',
        'react-redux',
        'react-router-dom',
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
        // Loaded indirectly by Shakapacker when assets_bundler is rspack.
        'shakapacker-rspack',
      ],
    },
  },
  // These test-only reset helpers are used across files (imported by test setup), but
  // `knip --production` strips test files and would report them as unused exports.
  ignoreIssues: {
    'packages/react-on-rails-pro-node-renderer/src/shared/tracing.ts': ['exports'],
    'packages/react-on-rails-pro-node-renderer/src/worker/fastifyConfig.ts': ['exports'],
    'packages/react-on-rails-pro-node-renderer/src/worker/shutdownHooks.ts': ['exports'],
  },
  ignoreExportsUsedInFile: true,
};

export default config;
