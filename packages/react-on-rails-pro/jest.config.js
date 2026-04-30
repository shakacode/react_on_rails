import { createRequire } from 'module';
import path from 'path';
import rootConfig from '../../jest.config.base.js';

const require = createRequire(import.meta.url);
const nodeVersion = parseInt(process.version.slice(1), 10);
const isReactServerEnv = (process.env.NODE_CONDITIONS ?? '')
  .split(',')
  .map((condition) => condition.trim())
  .includes('react-server');

// Resolve React package roots through Node's module resolution so the aliases
// follow workspace structure changes (renames, hoisting strategies, package
// manager swaps) instead of hardcoding `../../node_modules/react`.
const reactPackageRoot = path.dirname(require.resolve('react/package.json'));
const reactDomPackageRoot = path.dirname(require.resolve('react-dom/package.json'));

// Package-specific Jest configuration
// Inherits from root jest.config.mjs and adds package-specific settings
export default {
  // Inherit all settings from root
  ...rootConfig,

  // Override: Package-specific test directory
  testMatch: ['<rootDir>/tests/**/?(*.)+(spec|test).[jt]s?(x)'],

  // Package-specific: Jest setup files
  setupFiles: ['<rootDir>/tests/jest.setup.js'],

  // Package-specific: Module name mapping for React Server Components.
  // Only mock modules on Node versions < 18 where RSC features aren't available.
  //
  // The react/react-dom mappings dedupe React across workspace boundaries:
  // pnpm resolves @tanstack/react-router's react peer dep separately for this
  // workspace and the monorepo root, so hooks can otherwise see different
  // React instances. RSC tests need the `react-server` condition, so map them
  // directly to React's react-server entry files.
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
            '^react$': `${reactPackageRoot}/react.react-server.js`,
            '^react/jsx-runtime$': `${reactPackageRoot}/jsx-runtime.react-server.js`,
            '^react/jsx-dev-runtime$': `${reactPackageRoot}/jsx-dev-runtime.react-server.js`,
          }
        : {
            '^react$': reactPackageRoot,
            '^react/(.*)$': `${reactPackageRoot}/$1`,
            '^react-dom$': reactDomPackageRoot,
            '^react-dom/(.*)$': `${reactDomPackageRoot}/$1`,
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
