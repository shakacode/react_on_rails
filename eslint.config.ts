import path from 'node:path';
import { defineConfig, globalIgnores } from 'eslint/config';
import jest from 'eslint-plugin-jest';
import prettierRecommended from 'eslint-plugin-prettier/recommended';
import testingLibrary from 'eslint-plugin-testing-library';
import globals from 'globals';
import tsEslint from 'typescript-eslint';
import { includeIgnoreFile } from '@eslint/compat';
import js from '@eslint/js';
import { FlatCompat } from '@eslint/eslintrc';
import noUseClientInServerFiles from './eslint-rules/no-use-client-in-server-files.cjs';

const compat = new FlatCompat({
  baseDirectory: __dirname,
  recommendedConfig: js.configs.recommended,
  allConfig: js.configs.all,
});

// v6.1.1 does not expose a flat preset for these compiler-era Rules-of-React
// checks. Revisit this explicit list when bumping eslint-plugin-react-hooks.
const reactCompilerRulesOfReact = {
  'react-hooks/static-components': 'error',
  'react-hooks/use-memo': 'error',
  'react-hooks/component-hook-factories': 'error',
  'react-hooks/preserve-manual-memoization': 'error',
  'react-hooks/incompatible-library': 'warn',
  'react-hooks/immutability': 'error',
  'react-hooks/globals': 'error',
  'react-hooks/refs': 'error',
  'react-hooks/set-state-in-effect': 'error',
  'react-hooks/error-boundaries': 'error',
  'react-hooks/purity': 'error',
  'react-hooks/set-state-in-render': 'error',
  'react-hooks/unsupported-syntax': 'warn',
  'react-hooks/config': 'error',
  'react-hooks/gating': 'error',
} as const;

const config = defineConfig([
  // eslint-disable-next-line @typescript-eslint/no-unsafe-argument, @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-member-access
  includeIgnoreFile(path.resolve(__dirname, '.gitignore')),
  globalIgnores([
    // compiled code
    'packages/*/lib/',
    // used for tests only
    'spec/react_on_rails/dummy-for-generators',
    'react_on_rails/spec/dummy-for-generators',
    // temporary and generated files
    'react_on_rails/spec/dummy/.yalc',
    'react_on_rails_pro/spec/dummy/.yalc',
    'react_on_rails/spec/dummy/public',
    'react_on_rails_pro/spec/dummy/public',
    'react_on_rails/spec/dummy/vendor',
    'react_on_rails_pro/spec/dummy/vendor',
    'react_on_rails/spec/dummy/tmp',
    'react_on_rails_pro/spec/dummy/tmp',
    'react_on_rails/spec/dummy/app/assets/config/manifest.js',
    'react_on_rails_pro/spec/dummy/app/assets/config/manifest.js',
    'react_on_rails/spec/dummy/client/app/packs/server-bundle.js',
    'react_on_rails_pro/spec/dummy/client/app/packs/server-bundle.js',
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
    // Self-contained benchmark with its own pinned toolchain and checks.
    'benchmarks/rspack-vite-dx/',
    // dependencies
    '**/node_modules/',
    // fixtures
    '**/fixtures/',
    '**/.yalc/**/*',
    // generator templates - exclude TypeScript templates that need tsconfig.json
    '**/templates/**/*.tsx',
    '**/templates/**/*.ts',
    // test config files in packages - Jest/Babel configs cause ESM/CJS conflicts with ESLint
    'packages/*/tests/**',
    'packages/*/*.test.{js,jsx,ts,tsx}',
    'packages/*/babel.config.js',
    'packages/*/jest.config.js',
    // ShakaPerf reproduction inputs depend on the external `shaka-shared`
    // runtime and are committed as investigation artifacts, not repo TS source.
    'internal/analysis/rsc-fouc-shakaperf-artifacts/setup/ab-tests/**/*.ts',
    'internal/analysis/rsc-fouc-shakaperf-artifacts/setup/config/**/*.ts',
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
        alias: [['Assets', './react_on_rails/spec/dummy/client/app/assets']],

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
      // Disabled for flexibility with React 19 - allows both destructured and non-destructured props
      'react/destructuring-assignment': 'off',
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
    files: ['packages/**/*'],
    rules: {
      'import/extensions': ['error', 'ignorePackages'],
    },
  },
  {
    files: ['packages/**/src/**/*'],
    rules: {
      'import/extensions': ['error', 'ignorePackages'],
    },
  },
  {
    files: ['**/*.server.ts', '**/*.server.tsx'],
    plugins: {
      'react-on-rails': {
        rules: {
          'no-use-client-in-server-files': noUseClientInServerFiles,
        },
      },
    },
    rules: {
      'react-on-rails/no-use-client-in-server-files': 'error',
    },
  },
  {
    files: ['react_on_rails/lib/generators/react_on_rails/templates/**/*'],
    rules: {
      // It doesn't use package.json from the template
      'import/no-unresolved': 'off',
      // We have `const [name, setName] = useState(props.name)` so can't just destructure props
      'react/destructuring-assignment': 'off',
      // React 19 doesn't need PropTypes - we're targeting modern React
      'react/prop-types': 'off',
    },
  },
  {
    files: [
      'react_on_rails/spec/dummy/**/*',
      'react_on_rails_pro/spec/dummy/**/*',
      'react_on_rails_pro/spec/execjs-compatible-dummy/**/*',
    ],
    rules: {
      // The dummy app dependencies are managed separately and may not be installed
      'import/no-unresolved': 'off',
    },
  },
  {
    // Pro dummy apps were written under a more permissive lint config (see Pro's
    // pre-unification eslint.config.mjs). Keeping these rules off preserves
    // behavior; tightening them is out of scope for the lint-config unification.
    files: ['react_on_rails_pro/spec/dummy/**/*', 'react_on_rails_pro/spec/execjs-compatible-dummy/**/*'],
    rules: {
      'import/extensions': 'off',
      'import/prefer-default-export': 'off',
      'import/named': 'off',
      'react/prop-types': 'off',
      'no-underscore-dangle': 'off',
      // Pre-existing: a few .server.tsx files have 'use client' directives.
      // Not a regression introduced by unification; track fixing separately.
      'react-on-rails/no-use-client-in-server-files': 'off',
    },
  },
  {
    // Pro node-renderer integrations must only use the public integration API
    files: ['packages/react-on-rails-pro-node-renderer/src/integrations/**'],
    ignores: ['packages/react-on-rails-pro-node-renderer/src/integrations/api.ts'],
    rules: {
      'no-restricted-imports': ['error', { patterns: ['../*'] }],
    },
  },
  {
    // Pro Playwright e2e tests: fixtures use empty object patterns,
    // and Playwright's `test` function false-positives on react-hooks rules
    files: ['react_on_rails_pro/spec/dummy/e2e-tests/**/*'],
    rules: {
      'no-empty-pattern': ['error', { allowObjectPatternsAsParameters: true }],
      'react-hooks/rules-of-hooks': 'off',
    },
  },
  {
    files: ['**/e2e/playwright/**/*', '**/playwright/**/*.spec.{js,ts}'],
    rules: {
      // Playwright dependencies may not be installed during linting
      'import/no-unresolved': 'off',
    },
  },
  {
    files: ['**/*.ts{x,}', '**/*.[cm]ts'],

    extends: tsEslint.configs.strictTypeChecked,

    languageOptions: {
      parserOptions: {
        projectService: true,
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
          argsIgnorePattern: '^_',
          caughtErrorsIgnorePattern: '^_',
        },
      ],
      '@typescript-eslint/restrict-template-expressions': 'off',
    },
  },
  {
    files: ['packages/react-on-rails-pro/**/*'],
    rules: {
      // Disable import rules for pro package - can't resolve monorepo workspace imports
      // TypeScript compiler validates these imports
      'import/named': 'off',
      'import/no-unresolved': 'off',
      'import/no-cycle': 'off',
      'import/no-relative-packages': 'off',
      'import/no-duplicates': 'off',
      'import/extensions': 'off',
      'import/order': 'off',
      'import/no-self-import': 'off',
      'import/no-named-as-default': 'off',
      'import/no-named-as-default-member': 'off',
      'import/export': 'off',
      // Disable unsafe type rules - Pro package uses internal APIs with complex types
      '@typescript-eslint/no-unsafe-assignment': 'off',
      '@typescript-eslint/no-unsafe-call': 'off',
      '@typescript-eslint/no-unsafe-member-access': 'off',
      '@typescript-eslint/no-unsafe-return': 'off',
      '@typescript-eslint/no-unsafe-argument': 'off',
      '@typescript-eslint/no-redundant-type-constituents': 'off',
      // Allow deprecated React APIs for backward compatibility with React < 18
      '@typescript-eslint/no-deprecated': 'off',
      // Allow unbound methods - needed for method reassignment patterns
      '@typescript-eslint/unbound-method': 'off',
    },
  },
  {
    files: ['packages/react-on-rails-pro-node-renderer/**/*'],
    rules: {
      // Disable import rules for node-renderer - ESM requires .js extensions but ESLint
      // can't resolve them for .ts files. TypeScript compiler validates these imports
      'import/named': 'off',
      'import/no-unresolved': 'off',
      'import/prefer-default-export': 'off',
      // Disable unsafe type rules - node-renderer uses external libs with complex types
      '@typescript-eslint/no-unsafe-assignment': 'off',
      '@typescript-eslint/no-unsafe-call': 'off',
      '@typescript-eslint/no-unsafe-member-access': 'off',
      '@typescript-eslint/no-unsafe-return': 'off',
      '@typescript-eslint/no-unsafe-argument': 'off',
      // Allow missing extensions in require() calls - dynamic imports
      'import/extensions': 'off',
      // FastifyReply is a known-safe floating promise in node-renderer
      '@typescript-eslint/no-floating-promises': [
        'error',
        {
          allowForKnownSafePromises: [{ from: 'package', package: 'fastify', name: 'FastifyReply' }],
        },
      ],
    },
  },
  {
    files: ['packages/create-react-on-rails-app/**/*'],
    rules: {
      // Disable import rules for CLI package - CJS output with .js extensions in imports
      // can't be resolved by ESLint. TypeScript compiler validates these imports
      'import/no-unresolved': 'off',
    },
  },
  {
    files: ['**/app-react16/**/*'],
    rules: {
      'react/no-deprecated': 'off',
    },
  },
  {
    files: ['packages/*/tests/**', '**/*.test.{js,jsx,ts,tsx}'],

    extends: [
      jest.configs['flat/recommended'],
      jest.configs['flat/style'],
      testingLibrary.configs['flat/dom'],
    ],

    rules: {
      // Allows Jest mocks before import
      'import/first': 'off',
      // Avoiding these methods complicates tests and isn't useful for our purposes
      'testing-library/no-node-access': 'off',
    },
  },
  {
    files: ['packages/react-on-rails-pro-node-renderer/tests/**/*'],
    rules: {
      // Allow non-null assertions in tests - they're acceptable for test data
      '@typescript-eslint/no-non-null-assertion': 'off',
      // Some tests validate error conditions without explicit assertions
      'jest/expect-expect': 'off',
    },
  },
  {
    // Mirrors the Babel `sources` predicate in react_on_rails/spec/dummy/babel.config.js.
    // Keep these two in sync if the component is renamed or moved.
    files: ['react_on_rails/spec/dummy/client/app/startup/ReactCompilerExample.tsx'],
    rules: reactCompilerRulesOfReact,
  },
  // must be the last config in the array
  // https://github.com/prettier/eslint-plugin-prettier?tab=readme-ov-file#configuration-new-eslintconfigjs
  prettierRecommended,
]);

export default config;
