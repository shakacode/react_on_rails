import { createJsWithTsPreset } from 'ts-jest';

const nodeVersion = parseInt(process.version.slice(1), 10);

export default {
  ...createJsWithTsPreset({
    tsconfig: {
      // Relative imports in our TS code include `.ts` extensions.
      // When compiling the package, TS rewrites them to `.js`,
      // but ts-jest runs on the original code where the `.js` files don't exist,
      // so this setting needs to be disabled here.
      rewriteRelativeImportExtensions: false,
    },
  }),
  testEnvironment: 'jsdom',
  setupFiles: ['<rootDir>/node_package/tests/jest.setup.js'],
  // React Server Components tests are compatible with React 19
  // That only run with node version 18 and above
  moduleNameMapper:
    nodeVersion < 18
      ? {
          'react-on-rails-rsc/client': '<rootDir>/node_package/tests/emptyForTesting.js',
          '^@testing-library/dom$': '<rootDir>/node_package/tests/emptyForTesting.js',
          '^@testing-library/react$': '<rootDir>/node_package/tests/emptyForTesting.js',
        }
      : {},
};
