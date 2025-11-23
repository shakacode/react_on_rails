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
    'gen-documentation/',
    'spec/react_on_rails/dummy-for-generators',
    // includes some generated code
    'spec/dummy/client/app/packs/server-bundle.js',
    '../packages/react-on-rails/', // Ignore open-source package (has its own linting)
    '../packages/react-on-rails-pro-node-renderer/lib/',
    '../packages/react-on-rails-pro-node-renderer/tests/fixtures',
    '**/node_modules/',
    '**/assets/webpack/',
    '**/generated/',
    '**/app/assets/javascripts/application.js',
    '**/coverage/',
    '**/cable.js',
    '**/public/',
    '**/tmp/',
    '**/vendor/',
    '**/dist/',
    '**/.yalc/',
    '**/*.chunk.js',
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

        babelOptions: {
          presets: ['@babel/preset-env', '@babel/preset-react'],
        },
      },
    },

    settings: {
      'import/extensions': ['.js', '.ts'],

      'import/parsers': {
        '@typescript-eslint/parser': ['.ts'],
      },

      'import/resolver': {
        alias: [['Assets', './spec/dummy/client/app/assets']],
        node: true,
        typescript: true,
      },
    },

    rules: {
      'no-console': 'off',
      'no-underscore-dangle': 'off',
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
      'react/forbid-prop-types': 'off',
      'react/function-component-definition': [
        'error',
        {
          namedComponents: ['function-declaration', 'arrow-function'],
          unnamedComponents: 'arrow-function',
        },
      ],
      'react/jsx-filename-extension': [
        'error',
        {
          extensions: ['.jsx', '.tsx'],
        },
      ],
      'react/jsx-props-no-spreading': [
        'error',
        {
          custom: 'ignore',
        },
      ],
      'react/prop-types': 'off',
      'react/static-property-placement': 'off',
    },
  },
  {
    files: ['spec/dummy/**/*', 'spec/execjs-compatible-dummy'],
    languageOptions: {
      globals: globals.browser,
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
    files: ['../packages/react-on-rails-pro-node-renderer/tests/**', '**/*.test.{js,jsx,ts,tsx}'],

    extends: [jest.configs['flat/recommended'], jest.configs['flat/style']],

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
    files: ['../packages/react-on-rails-pro-node-renderer/src/integrations/**'],
    ignores: ['../packages/react-on-rails-pro-node-renderer/src/integrations/api.ts'],

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
  {
    files: ['spec/dummy/e2e-tests/*'],

    rules: {
      'no-empty-pattern': [
        'error',
        {
          allowObjectPatternsAsParameters: true,
        },
      ],
    },
  },
  {
    files: ['spec/dummy/e2e-tests/*'],
    rules: {
      'react-hooks/rules-of-hooks': ['off'],
    },
  },
  // must be the last config in the array
  // https://github.com/prettier/eslint-plugin-prettier?tab=readme-ov-file#configuration-new-eslintconfigjs
  prettierRecommended,
]);
