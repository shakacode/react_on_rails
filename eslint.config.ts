import path from 'node:path';
import { globalIgnores } from 'eslint/config';
import jest from 'eslint-plugin-jest';
import prettierRecommended from 'eslint-plugin-prettier/recommended';
import globals from 'globals';
import tsEslint from 'typescript-eslint';
import { includeIgnoreFile } from '@eslint/compat';
import js from '@eslint/js';
import { FlatCompat } from '@eslint/eslintrc';

const compat = new FlatCompat({
  baseDirectory: __dirname,
  recommendedConfig: js.configs.recommended,
  allConfig: js.configs.all,
});

const config = tsEslint.config([
  includeIgnoreFile(path.resolve(__dirname, '.gitignore')),
  globalIgnores([
    // compiled code
    'node_package/lib/',
    // used for tests only
    'spec/react_on_rails/dummy-for-generators',
    // temporary and generated files
    'spec/dummy/.yalc',
    'spec/dummy/public',
    'spec/dummy/vendor',
    'spec/dummy/tmp',
    'spec/dummy/app/assets/config/manifest.js',
    'spec/dummy/client/app/packs/server-bundle.js',
    '**/*.res.js',
    '**/coverage',
    '**/assets/webpack/',
    '**/public/webpack/',
    '**/generated/',
    '**/app/assets/javascripts/application.js',
    '**/cable.js',
    '**/public/packs*/',
    '**/gen-examples/',
    '**/bundle/',
    // dependencies
    '**/node_modules/',
    // fixtures
    '**/fixtures/',
    '**/.yalc/**/*',
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
          extensions: ['.js', '.jsx', '.ts', '.tsx', '.d.ts'],
        },
      },
    },

    rules: {
      'no-shadow': 'off',
      'no-console': 'off',
      'function-paren-newline': 'off',
      'object-curly-newline': 'off',
      'no-restricted-syntax': ['error', 'SequenceExpression'],
      'no-void': [
        'error',
        {
          allowAsStatement: true,
        },
      ],

      'import/extensions': [
        'error',
        'ignorePackages',
        {
          js: 'never',
          jsx: 'never',
          ts: 'never',
          tsx: 'never',
        },
      ],

      'import/first': 'off',
      'import/no-extraneous-dependencies': 'off',
      // The rule seems broken: it's reporting errors on imports in files using `export` too,
      // not just `module.exports`.
      'import/no-import-module-exports': 'off',
      'import/no-unresolved': [
        'error',
        {
          ignore: ['\\.res\\.js$'],
        },
      ],
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
      'react/jsx-filename-extension': [
        'error',
        {
          extensions: ['.jsx', '.tsx'],
        },
      ],
    },
  },
  {
    files: ['node_package/**/*'],
    rules: {
      'import/extensions': ['error', 'ignorePackages'],
    },
  },
  {
    files: ['lib/generators/react_on_rails/templates/**/*'],
    rules: {
      // It doesn't use package.json from the template
      'import/no-unresolved': 'off',
      // We have `const [name, setName] = useState(props.name)` so can't just destructure props
      'react/destructuring-assignment': 'off',
    },
  },
  {
    files: ['**/*.ts{x,}', '**/*.[cm]ts'],

    extends: tsEslint.configs.strictTypeChecked,

    languageOptions: {
      parserOptions: {
        projectService: {
          allowDefaultProject: ['eslint.config.ts', 'knip.ts', 'node_package/tests/*.test.ts'],
          // Needed because `import * as ... from` instead of `import ... from` doesn't work in this file
          // for some imports.
          defaultProject: 'tsconfig.eslint.json',
        },
      },
    },

    rules: {
      '@typescript-eslint/no-namespace': 'off',
      '@typescript-eslint/no-shadow': 'error',
      '@typescript-eslint/no-confusing-void-expression': [
        'error',
        {
          ignoreArrowShorthand: true,
        },
      ],
      // Too many false positives
      '@typescript-eslint/no-unnecessary-condition': 'off',
      '@typescript-eslint/no-unused-vars': [
        'error',
        {
          caughtErrorsIgnorePattern: '^_',
        },
      ],
      '@typescript-eslint/restrict-template-expressions': 'off',
    },
  },
  {
    files: ['**/app-react16/**/*'],
    rules: {
      'react/no-deprecated': 'off',
    },
  },
  {
    files: ['node_package/tests/**', '**/*.test.{js,jsx,ts,tsx}'],

    extends: [jest.configs['flat/recommended'], jest.configs['flat/style']],

    rules: {
      // Allows Jest mocks before import
      'import/first': 'off',
    },
  },
  // must be the last config in the array
  // https://github.com/prettier/eslint-plugin-prettier?tab=readme-ov-file#configuration-new-eslintconfigjs
  prettierRecommended,
]);

export default config;
