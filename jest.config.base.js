import { createJsWithTsPreset } from 'ts-jest';

const tsconfig = {
  // Relative imports in our TS code include `.ts` extensions.
  // When compiling the package, TS rewrites them to `.js`,
  // but ts-jest runs on the original code where the `.js` files don't exist,
  // so this setting needs to be disabled here.
  rewriteRelativeImportExtensions: false,
  // Override hybrid module kind (Node16/NodeNext) to avoid ts-jest warning
  // about requiring isolatedModules: true
  module: 'ESNext',
};

const tsJestPreset = createJsWithTsPreset({
  tsconfig,
});

// Global Jest configuration for the monorepo
// Contains common settings that all packages inherit
export default {
  // === TypeScript Configuration ===
  // ts-jest preset with custom TypeScript settings, extended to handle .cts/.mts files
  ...tsJestPreset,
  transform: {
    ...tsJestPreset.transform,
    // Extend transform to include CommonJS TypeScript (.cts) and ES Module TypeScript (.mts) files
    '^.+\\.[cm]?ts$': [
      'ts-jest',
      {
        tsconfig,
      },
    ],
  },

  // === Test Environment Configuration ===
  testEnvironment: 'jsdom',

  // === Common Test Patterns ===
  // Default test pattern - packages can override this
  testMatch: ['**/?(*.)+(spec|test).[jt]s?(x)'],

  // === Common Module File Extensions ===
  // Include cts/mts for CommonJS/ES module TypeScript files
  moduleFileExtensions: ['js', 'jsx', 'ts', 'tsx', 'cts', 'mts', 'json'],
};
