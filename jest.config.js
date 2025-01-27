module.exports = {
  preset: 'ts-jest/presets/js-with-ts',
  testEnvironment: 'jsdom',
  setupFiles: ['<rootDir>/node_package/tests/jest.setup.js'],
  // TODO: Remove this once we made RSCClientRoot compatible with React 19
  moduleNameMapper: process.env.USE_REACT_18
    ? {
        '^react$': '<rootDir>/node_modules/react-18',
        '^react/(.*)$': '<rootDir>/node_modules/react-18/$1',
        '^react-dom$': '<rootDir>/node_modules/react-dom-18',
        '^react-dom/(.*)$': '<rootDir>/node_modules/react-dom-18/$1',
      }
    : {
        'react-server-dom-webpack/client': '<rootDir>/node_package/tests/emptyForTesting.js',
      },
};
