// Jest config for the Pro dummy app.
//
// Pins behaviors of `client/app/strictModeSupport.tsx` that aren't exercised by the OSS dummy's
// Jest suite (Pro's `enableStrictModeForReactOnRails` singleton patch and the async Promise path
// in `wrapRenderFunctionResult`).
//
// Uses ts-jest directly rather than the dummy's `babel.config.js`, which carries webpack-specific
// plugins (macros, loadable, react-refresh) that aren't safe to run inside the test runner.

const { createJsWithTsPreset } = require('ts-jest');

const tsJestPreset = createJsWithTsPreset({
  tsconfig: {
    jsx: 'react',
    esModuleInterop: true,
    module: 'ESNext',
    target: 'ES2020',
  },
});

module.exports = {
  ...tsJestPreset,
  testEnvironment: 'jsdom',
  testMatch: ['<rootDir>/tests/**/?(*.)+(spec|test).[jt]s?(x)'],
  moduleFileExtensions: ['js', 'jsx', 'ts', 'tsx', 'json'],
  clearMocks: true,
  rootDir: '.',
};
