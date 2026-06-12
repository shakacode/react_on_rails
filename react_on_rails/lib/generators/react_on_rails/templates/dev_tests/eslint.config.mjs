import js from '@eslint/js';
import prettier from 'eslint-config-prettier';
import importPlugin from 'eslint-plugin-import';
import react from 'eslint-plugin-react';
import reactHooks from 'eslint-plugin-react-hooks';
import globals from 'globals';

const reactHooksRecommendedLatest = reactHooks.configs['recommended-latest'];
const reactHooksRecommendedLatestConfigs = Array.isArray(reactHooksRecommendedLatest)
  ? reactHooksRecommendedLatest
  : [reactHooksRecommendedLatest];

export default [
  js.configs.recommended,
  react.configs.flat.recommended,
  importPlugin.flatConfigs.recommended,
  ...reactHooksRecommendedLatestConfigs,
  {
    files: ['**/*.{js,jsx,mjs,cjs}'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: {
        ...globals.browser,
        ...globals.node,
        ...globals.mocha,
        __DEBUG_SERVER_ERRORS__: true,
        __SERVER_ERRORS__: true,
      },
    },
    plugins: {
      import: importPlugin,
    },
    settings: {
      react: {
        version: 'detect',
      },
    },
    rules: {
      'no-console': 'off',

      // https://github.com/import-js/eslint-plugin-import/issues/340
      'import/no-extraneous-dependencies': 'off',

      // The internal generated examples use local workspace packages during tests.
      'import/no-unresolved': 'off',

      'react/prop-types': 'off',
      semi: 'off',
    },
  },
  prettier,
];
