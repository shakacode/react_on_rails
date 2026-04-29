import rootConfig from '../../jest.config.base.js';

const nodeVersion = parseInt(process.version.slice(1), 10);

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
  moduleNameMapper:
    nodeVersion < 18
      ? {
          'react-on-rails-rsc/client': '<rootDir>/tests/emptyForTesting.js',
          '^@testing-library/dom$': '<rootDir>/tests/emptyForTesting.js',
          '^@testing-library/react$': '<rootDir>/tests/emptyForTesting.js',
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
