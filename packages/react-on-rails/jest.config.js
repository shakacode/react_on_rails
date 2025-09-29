// eslint-disable-next-line import/no-relative-packages, import/extensions
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
      : {},

  // Set root directory to current package
  rootDir: '.',
};
