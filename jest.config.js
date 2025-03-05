const nodeVersion = parseInt(process.version.slice(1), 10);

module.exports = {
  preset: 'ts-jest/presets/js-with-ts',
  testEnvironment: 'jsdom',
  setupFiles: ['<rootDir>/node_package/tests/jest.setup.js'],
  // React Server Components tests are compatible with React 19
  // That only run with node version 18 and above
  moduleNameMapper:
    nodeVersion < 18
      ? {
          '@shakacode-tools/react-on-rails-rsc/client': '<rootDir>/node_package/tests/emptyForTesting.js',
          '^@testing-library/dom$': '<rootDir>/node_package/tests/emptyForTesting.js',
          '^@testing-library/react$': '<rootDir>/node_package/tests/emptyForTesting.js',
        }
      : {},
};
