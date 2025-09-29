import { createJsWithTsPreset } from 'ts-jest';

// Global Jest configuration for the monorepo
// Contains common settings that all packages inherit
export default {
  // === TypeScript Configuration ===
  // ts-jest preset with custom TypeScript settings
  ...createJsWithTsPreset({
    tsconfig: {
      // Relative imports in our TS code include `.ts` extensions.
      // When compiling the package, TS rewrites them to `.js`,
      // but ts-jest runs on the original code where the `.js` files don't exist,
      // so this setting needs to be disabled here.
      rewriteRelativeImportExtensions: false,
    },
  }),

  // === Test Environment Configuration ===
  testEnvironment: 'jsdom',

  // === Common Test Patterns ===
  // Default test pattern - packages can override this
  testMatch: ['**/?(*.)+(spec|test).[jt]s?(x)'],

  // === Common Module File Extensions ===
  moduleFileExtensions: ['js', 'jsx', 'ts', 'tsx', 'json'],
};
