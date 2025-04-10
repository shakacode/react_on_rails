import path from 'node:path';
import { includeIgnoreFile } from '@eslint/compat';
import js from '@eslint/js';
import { FlatCompat } from '@eslint/eslintrc';
import { defineConfig, globalIgnores } from 'eslint/config';
import importPlugin from 'eslint-plugin-import';
import jest from 'eslint-plugin-jest';
import prettierRecommended from 'eslint-plugin-prettier/recommended';
import globals from 'globals';
import typescriptEslint from 'typescript-eslint';

const compat = new FlatCompat({
  baseDirectory: import.meta.dirname,
  recommendedConfig: js.configs.recommended,
  allConfig: js.configs.all,
});

export default defineConfig([
  includeIgnoreFile(path.resolve(import.meta.dirname, '.gitignore')),
  globalIgnores([
    '**/node_modules',
    '**/coverage',
    'gen-documentation/**/*',
    'spec/react_on_rails/dummy-for-generators',
    'spec/dummy',
    'spec/execjs-compatible-dummy',
    'packages/node-renderer/lib/',
    'packages/node-renderer/tests/fixtures',
    'packages/node-renderer/webpack.config.js',
    '**/node_modules/**/*',
    '**/assets/webpack/**/*',
    '**/generated/**/*',
    '**/app/assets/javascripts/application.js',
    '**/coverage/**/*',
    '**/cable.js',
    '**/public/**/*',
    '**/tmp/**/*',
    '**/vendor',
    '**/dist',
    '**/.yalc/',
  ]),
  {
    files: ['**/*.[jt]s', '**/*.[cm][jt]s', '**/*.[jt]sx'],
  },
  js.configs.recommended,
  compat.extends('eslint-config-shakacode'),
  {
    languageOptions: {
      globals: globals.node,

      parserOptions: {
        // We have @babel/eslint-parser from eslint-config-shakacode, but don't use Babel in the main project
        requireConfigFile: false,
      },
    },

    settings: {
      'import/extensions': ['.js', '.ts'],

      'import/parsers': {
        '@typescript-eslint/parser': ['.ts'],
      },

      'import/resolver': {
        node: true,
        typescript: true,
      },
    },

    rules: {
      'no-console': 'off',

      'no-void': [
        'error',
        {
          // Allow using void to suppress errors about misused promises
          allowAsStatement: true,
        },
      ],

      // Allow using void to suppress errors about misused promises
      'no-restricted-syntax': 'off',
      // https://github.com/benmosher/eslint-plugin-import/issues/340
      'import/no-extraneous-dependencies': 'off',
      'import/extensions': 'off',
      'import/prefer-default-export': 'off',
      'lines-between-class-members': [
        'error',
        {
          enforce: [
            { blankLine: 'always', prev: '*', next: '*' },
            { blankLine: 'never', prev: 'field', next: 'field' },
          ],
        },
      ],
      'no-mixed-operators': 'off',
    },
  },
  {
    files: ['**/*.ts{x,}'],
    extends: [importPlugin.flatConfigs.typescript, typescriptEslint.configs.strictTypeChecked],

    languageOptions: {
      parserOptions: {
        projectService: true,
      },
    },

    rules: {
      '@typescript-eslint/restrict-template-expressions': 'off',

      '@typescript-eslint/no-unused-vars': [
        'error',
        {
          argsIgnorePattern: '^_',
          caughtErrorsIgnorePattern: '^_',
        },
      ],

      '@typescript-eslint/no-floating-promises': [
        'error',
        {
          allowForKnownSafePromises: [
            {
              from: 'package',
              package: 'fastify',
              name: 'FastifyReply',
            },
          ],
        },
      ],

      'no-shadow': 'off',
      '@typescript-eslint/no-shadow': 'error',
    },
  },
  {
    files: ['packages/node-renderer/tests/**'],

    plugins: {
      jest,
    },

    languageOptions: {
      globals: globals.jest,
    },

    rules: {
      // Allows Jest mocks before import
      'import/first': 'off',
      'jest/no-disabled-tests': 'warn',
      'jest/no-focused-tests': 'error',
      'jest/no-identical-title': 'error',
      'jest/prefer-to-have-length': 'warn',
      'jest/valid-expect': 'error',
      // Simplifies test code
      '@typescript-eslint/no-non-null-assertion': 'off',
    },
  },
  {
    files: ['packages/node-renderer/src/integrations/**'],
    ignores: ['packages/node-renderer/src/integrations/api.ts'],

    rules: {
      // Integrations should only use the public integration API
      'no-restricted-imports': [
        'error',
        {
          patterns: ['../*'],
        },
      ],
    },
  },
  // must be the last config in the array
  // https://github.com/prettier/eslint-plugin-prettier?tab=readme-ov-file#configuration-new-eslintconfigjs
  prettierRecommended,
]);
