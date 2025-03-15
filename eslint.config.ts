import { globalIgnores } from 'eslint/config';
import prettierRecommended from 'eslint-plugin-prettier/recommended';
import globals from 'globals';
import tsEslint from 'typescript-eslint';
import js from '@eslint/js';
import { FlatCompat } from '@eslint/eslintrc';

const compat = new FlatCompat({
  baseDirectory: __dirname,
  recommendedConfig: js.configs.recommended,
  allConfig: js.configs.all,
});

const config = tsEslint.config([
  globalIgnores([
    'lib/generators/react_on_rails/templates',
    'node_package/lib/',
    'spec/react_on_rails/dummy-for-generators',
    'spec/dummy/.yalc',
    'spec/dummy/public',
    'spec/dummy/vendor',
    'spec/dummy/tmp',
    'spec/dummy/app/assets/config/manifest.js',
    '**/*.res.js',
    '**/coverage',
    '**/node_modules/**/*',
    '**/assets/webpack/**/*',
    '**/public/webpack/**/*',
    '**/generated/**/*',
    '**/app/assets/javascripts/application.js',
    '**/coverage/**/*',
    '**/cable.js',
    '**/public/packs*/*',
    '**/gen-examples',
    '**/bundle/',
    // These files can't be included in tsconfig.json because they can't be compiled under Node 16
    'eslint.config.ts',
    'knip.ts',
  ]),
  {
    files: ['**/*.[jt]s', '**/*.[jt]sx', '**/*.[cm][jt]s'],
  },
  js.configs.recommended,
  compat.extends('eslint-config-shakacode'),
  {
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.node,
        ...globals.mocha,
        ...globals.jest,
        __DEBUG_SERVER_ERRORS__: true,
        __SERVER_ERRORS__: true,
      },

      parserOptions: {
        requireConfigFile: false,

        babelOptions: {
          presets: ['@babel/preset-env', '@babel/preset-react'],
        },
      },
    },

    settings: {
      'import/core-modules': ['react-redux'],

      'import/resolver': {
        alias: [['Assets', './spec/dummy/client/app/assets']],

        node: {
          extensions: ['.js', '.jsx', '.ts', '.d.ts'],
        },
      },
    },

    rules: {
      'no-shadow': 'off',
      'no-console': 'off',
      'function-paren-newline': 'off',
      'object-curly-newline': 'off',
      'no-restricted-syntax': ['error', 'SequenceExpression'],

      'import/extensions': [
        'error',
        'ignorePackages',
        {
          js: 'never',
          jsx: 'never',
          ts: 'never',
        },
      ],

      'import/first': 'off',
      'import/no-extraneous-dependencies': 'off',
      // The rule seems broken: it's reporting errors on imports in files using `export` too,
      // not just `module.exports`.
      'import/no-import-module-exports': 'off',
      'react/destructuring-assignment': [
        'error',
        'always',
        {
          ignoreClassFields: true,
        },
      ],
      'react/forbid-prop-types': 'off',
      'react/function-component-definition': [
        'error',
        {
          namedComponents: ['arrow-function', 'function-declaration'],
          unnamedComponents: 'arrow-function',
        },
      ],
      'react/jsx-props-no-spreading': 'off',
      'react/static-property-placement': 'off',
      'jsx-a11y/anchor-is-valid': 'off',
    },
  },
  {
    files: ['**/*.ts', '**/*.tsx'],

    extends: tsEslint.configs.recommended,

    languageOptions: {
      parserOptions: {
        project: true,
      },
    },

    rules: {
      '@typescript-eslint/no-namespace': 'off',
      '@typescript-eslint/no-shadow': 'error',
      '@typescript-eslint/no-unused-vars': [
        'error',
        {
          caughtErrorsIgnorePattern: '^_',
        },
      ],
    },
  },
  // must be the last config in the array
  // https://github.com/prettier/eslint-plugin-prettier?tab=readme-ov-file#configuration-new-eslintconfigjs
  prettierRecommended,
]);

export default config;
