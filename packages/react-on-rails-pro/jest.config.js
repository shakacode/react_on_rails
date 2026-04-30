import rootConfig from '../../jest.config.base.js';

const nodeVersion = parseInt(process.version.slice(1), 10);
const isReactServerEnv = (process.env.NODE_CONDITIONS ?? '')
  .split(',')
  .map((c) => c.trim())
  .includes('react-server');

// Package-specific Jest configuration
// Inherits from root jest.config.mjs and adds package-specific settings
export default {
  // Inherit all settings from root
  ...rootConfig,

  // Override: Package-specific test directory
  testMatch: ['<rootDir>/tests/**/?(*.)+(spec|test).[jt]s?(x)'],

  // Package-specific: Jest setup files
  setupFiles: ['<rootDir>/tests/jest.setup.js'],

  // Package-specific: Module name mapping for React Server Components
  // Only mock modules on Node versions < 18 where RSC features aren't available
  // eslint-disable-next-line no-nested-ternary
  moduleNameMapper:
    nodeVersion < 18
      ? {
          'react-on-rails-rsc/client': '<rootDir>/tests/emptyForTesting.js',
          '^@testing-library/dom$': '<rootDir>/tests/emptyForTesting.js',
          '^@testing-library/react$': '<rootDir>/tests/emptyForTesting.js',
        }
      : isReactServerEnv
        ? {
            // Under NODE_CONDITIONS=react-server (the test:rsc bucket), an
            // empty moduleNameMapper would leave the package-local React copy
            // and the workspace-root React (used by `react-on-rails-rsc`) as
            // two separate instances. Today's RSC tests don't cross that
            // boundary with hooks, but the next one that does would explode.
            // Dedupe deterministically by mapping directly to the root copy's
            // `react-server` build files — a moduleNameMapper redirect to a
            // *directory* path would defeat Jest's customExportConditions
            // resolution (selecting `index.js` instead of
            // `react.react-server.js`); pointing at the file directly side-
            // steps that. The exact filenames used here are the targets
            // listed in `react`'s own `package.json#exports` for the
            // `react-server` condition (stable across React 19.x).
            '^react$': '<rootDir>/../../node_modules/react/react.react-server.js',
            '^react/jsx-runtime$': '<rootDir>/../../node_modules/react/jsx-runtime.react-server.js',
            '^react/jsx-dev-runtime$': '<rootDir>/../../node_modules/react/jsx-dev-runtime.react-server.js',
            // react-dom is intentionally not remapped: RSC tests do not render
            // to DOM and don't import any react-dom subpath. Leave resolution
            // alone to avoid masking real bugs.
          }
        : {
            // Dedupe React/React-DOM to the workspace root copy so that hooks
            // called from this package's source share a single dispatcher with
            // @testing-library/react (which resolves React from the root). Two
            // copies → "Cannot read properties of null (reading 'useRef')".
            // The `react-dom/(.*)` mapper is required because react-dom asserts
            // it shares an exact version with react.
            '^react$': '<rootDir>/../../node_modules/react',
            '^react-dom$': '<rootDir>/../../node_modules/react-dom',
            '^react-dom/(.*)$': '<rootDir>/../../node_modules/react-dom/$1',
            '^react/jsx-runtime$': '<rootDir>/../../node_modules/react/jsx-runtime',
            '^react/jsx-dev-runtime$': '<rootDir>/../../node_modules/react/jsx-dev-runtime',
          },

  // Allow Jest to transform react-on-rails package from node_modules
  transformIgnorePatterns: ['node_modules/(?!react-on-rails)'],
  // RSC tests needs the node condition "react-server" to run
  // So, before running these tests, we set "NODE_CONDITIONS=react-server"
  testEnvironmentOptions: process.env.NODE_CONDITIONS
    ? {
        customExportConditions: process.env.NODE_CONDITIONS.split(','),
      }
    : {},
  // Set root directory to current package
  rootDir: '.',
};
