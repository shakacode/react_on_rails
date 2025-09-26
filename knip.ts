import type { KnipConfig } from 'knip';

const config: KnipConfig = {
  // ! at the end means files are used in production
  workspaces: {
    '.': {
      entry: [
        'packages/react-on-rails/src/ReactOnRails.node.ts!',
        'packages/react-on-rails/src/pro/ReactOnRailsRSC.ts!',
        'packages/react-on-rails/src/pro/registerServerComponent/client.tsx!',
        'packages/react-on-rails/src/pro/registerServerComponent/server.tsx!',
        'packages/react-on-rails/src/pro/registerServerComponent/server.rsc.ts!',
        'packages/react-on-rails/src/pro/wrapServerComponentRenderer/server.tsx!',
        'packages/react-on-rails/src/pro/wrapServerComponentRenderer/server.rsc.tsx!',
        'packages/react-on-rails/src/pro/RSCRoute.tsx!',
        'packages/react-on-rails/src/pro/ServerComponentFetchError.ts!',
        'packages/react-on-rails/src/pro/getReactServerComponent.server.ts!',
        'packages/react-on-rails/src/pro/transformRSCNodeStream.ts!',
        'packages/react-on-rails/src/loadJsonFile.ts!',
        'eslint.config.ts',
      ],
      project: [
        'packages/react-on-rails/src/**/*.[jt]s{x,}!',
        'node_package/tests/**/*.[jt]s{x,}',
        '!react_on_rails_pro/**',
      ],
      babel: {
        config: ['node_package/babel.config.js'],
      },
      ignore: [
        'node_package/tests/emptyForTesting.js',
        // Pro features exported for external consumption
        'packages/react-on-rails/src/pro/streamServerRenderedReactComponent.ts:transformRenderStreamChunksToResultObject',
        'packages/react-on-rails/src/pro/streamServerRenderedReactComponent.ts:streamServerRenderedComponent',
        'packages/react-on-rails/src/pro/ServerComponentFetchError.ts:isServerComponentFetchError',
        'packages/react-on-rails/src/pro/RSCRoute.tsx:RSCRouteProps',
        'packages/react-on-rails/src/pro/streamServerRenderedReactComponent.ts:StreamingTrackers',
        // Exclude entire pro directory - it has its own package.json with dependencies
        'react_on_rails_pro/**',
      ],
      ignoreBinaries: [
        // Knip fails to detect it's declared in devDependencies
        'nps',
        // local scripts
        'node_package/scripts/.*',
      ],
      ignoreDependencies: [
        // Required for TypeScript compilation, but we don't depend on Turbolinks itself.
        '@types/turbolinks',
        // Keep this even though knip doesn't detect usage
        '@babel/preset-typescript',
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
