module.exports = {
  preset: 'ts-jest/presets/js-with-ts',
  testEnvironment: 'jsdom',
  setupFiles: ['<rootDir>/node_package/tests/jest.setup.js'],
};
