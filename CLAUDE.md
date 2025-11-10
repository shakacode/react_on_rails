# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## ⚠️ CRITICAL REQUIREMENTS

**BEFORE EVERY COMMIT/PUSH:**

1. **ALWAYS run `bundle exec rubocop` and fix ALL violations**
2. **ALWAYS ensure files end with a newline character**
3. **NEVER push without running full lint check first**
4. **ALWAYS let Prettier and RuboCop handle ALL formatting - never manually format**

These requirements are non-negotiable. CI will fail if not followed.

**🚀 AUTOMATIC: Git hooks are installed automatically during setup**

Git hooks will automatically run linting on **all changed files (staged + unstaged + untracked)** before each commit - making it fast while preventing CI failures!

Pre-commit hooks automatically run:
- **RuboCop** (auto-fix Ruby code style)
- **ESLint** (auto-fix JS/TS code style)
- **Prettier** (auto-format all supported files)
- **Trailing newline checks** (ensure all files end with newlines)

**Note:** Git hooks are for React on Rails gem developers only, not for users who install the gem.

## Development Commands

### Essential Commands

- **Install dependencies**: `bundle && yarn`
- **Run tests**:
  - Ruby tests: `rake run_rspec`
  - JavaScript tests: `yarn run test` or `rake js_tests`
  - All tests: `rake` (default task runs lint and all tests except examples)
- **Linting** (MANDATORY BEFORE EVERY COMMIT):
  - **REQUIRED**: `bundle exec rubocop` - Must pass with zero offenses
  - All linters: `rake lint` (runs ESLint and RuboCop)
  - ESLint only: `yarn run lint` or `rake lint:eslint`
  - RuboCop only: `rake lint:rubocop`
- **Code Formatting**:
  - Format code with Prettier: `rake autofix`
  - Check formatting without fixing: `yarn start format.listDifferent`
- **Build**: `yarn run build` (compiles TypeScript to JavaScript in packages/react-on-rails/lib)
- **Type checking**: `yarn run type-check`
- **RBS Type Checking**:
  - Validate RBS signatures: `bundle exec rake rbs:validate`
  - Run Steep type checker: `bundle exec rake rbs:steep`
  - Run both: `bundle exec rake rbs:all`
  - List RBS files: `bundle exec rake rbs:list`
- **⚠️ MANDATORY BEFORE GIT PUSH**: `bundle exec rubocop` and fix ALL violations + ensure trailing newlines
- Never run `npm` commands, only equivalent Yarn Classic ones

## RBS Type Checking

React on Rails uses RBS (Ruby Signature) for static type checking with Steep.

### Quick Start

- **Validate signatures**: `bundle exec rake rbs:validate` (run by CI)
- **Run type checker**: `bundle exec rake rbs:steep` (currently disabled in CI due to existing errors)
- **Runtime checking**: Enabled by default in tests when `rbs` gem is available

### Runtime Type Checking

Runtime type checking is **ENABLED BY DEFAULT** during test runs for:
- `rake run_rspec:gem` - Unit tests
- `rake run_rspec:dummy` - Integration tests
- `rake run_rspec:dummy_no_turbolinks` - Integration tests without Turbolinks

To disable runtime checking (e.g., for faster test runs):
```bash
DISABLE_RBS_RUNTIME_CHECKING=true rake run_rspec:gem
```

### Adding Type Signatures

When creating new Ruby files in `lib/react_on_rails/`:

1. **Create RBS signature**: Add `sig/react_on_rails/filename.rbs`
2. **Add to Steepfile**: Include `check "lib/react_on_rails/filename.rb"` in Steepfile
3. **Validate**: Run `bundle exec rake rbs:validate`
4. **Type check**: Run `bundle exec rake rbs:steep`
5. **Fix errors**: Address any type errors before committing

### Files Currently Type-Checked

See `Steepfile` for the complete list. Core files include:
- `lib/react_on_rails.rb`
- `lib/react_on_rails/configuration.rb`
- `lib/react_on_rails/helper.rb`
- `lib/react_on_rails/packer_utils.rb`
- `lib/react_on_rails/server_rendering_pool.rb`
- And 5 more (see Steepfile for full list)

### Pro Package Type Checking

The Pro package has its own RBS signatures in `react_on_rails_pro/sig/`.

Validate Pro signatures:
```bash
cd react_on_rails_pro && bundle exec rbs -I sig validate
```

## Changelog

- **Update CHANGELOG.md for user-visible changes only** (features, bug fixes, breaking changes, deprecations, performance improvements)
- **Do NOT add entries for**: linting, formatting, refactoring, tests, or documentation fixes
- **Format**: `[PR 1818](https://github.com/shakacode/react_on_rails/pull/1818) by [username](https://github.com/username)` (no hash in PR number)
- **Use `/update-changelog` command** for guided changelog updates with automatic formatting
- **Version management**: Run `bundle exec rake update_changelog` after releases to update version headers
- **Examples**: Run `grep -A 3 "^#### " CHANGELOG.md | head -30` to see real formatting examples

## ⚠️ FORMATTING RULES

**Prettier is the SOLE authority for formatting non-Ruby files, and RuboCop for formatting Ruby files. NEVER manually format code.**

### Standard Workflow
1. Make code changes
2. Run `rake autofix` or `yarn start format`
3. Commit changes

### Merge Conflict Resolution Workflow
**CRITICAL**: When resolving merge conflicts, follow this exact sequence:

1. **Resolve logical conflicts only** - don't worry about formatting
2. **Add resolved files**: `git add .` (or specific files)
3. **Auto-fix everything**: `rake autofix`
4. **Add any formatting changes**: `git add .`
5. **Continue rebase/merge**: `git rebase --continue` or `git commit`

**❌ NEVER manually format during conflict resolution** - this causes formatting wars between tools.

### Debugging Formatting Issues
- Check current formatting: `yarn start format.listDifferent`
- Fix all formatting: `rake autofix`
- If CI fails on formatting, always run automated fixes, never manual fixes

### Development Setup Commands

- **Initial setup**: `bundle && yarn && rake shakapacker_examples:gen_all && rake node_package && rake`
- **Prepare examples**: `rake shakapacker_examples:gen_all`
- **Generate node package**: `rake node_package`
- **Run single test example**: `rake run_rspec:example_basic`

### Test Environment Commands

- **Dummy app tests**: `rake run_rspec:dummy`
- **Gem-only tests**: `rake run_rspec:gem`
- **All tests except examples**: `rake all_but_examples`

## Project Architecture

### Monorepo Structure

This is a monorepo containing both the open-source package and the Pro package:

- **Open Source**: Root directory contains the main React on Rails gem and package
- **Pro Package**: `react_on_rails_pro/` contains the Pro features (separate linting/formatting config)
- **Ruby gem**: Located in `lib/`, provides Rails integration and server-side rendering
- **NPM package**: Located in `packages/react-on-rails/src/`, provides client-side React integration

**IMPORTANT**: The `react_on_rails_pro/` directory has its own Prettier/ESLint configuration. When CI runs, it lints both directories separately. The pre-commit hooks will catch issues in both directories.

### Core Components

#### Ruby Side (`lib/react_on_rails/`)

- **`helper.rb`**: Rails view helpers for rendering React components
- **`server_rendering_pool.rb`**: Manages Node.js processes for server-side rendering
- **`configuration.rb`**: Global configuration management
- **`engine.rb`**: Rails engine integration
- **Generators**: Located in `lib/generators/react_on_rails/`

#### JavaScript/TypeScript Side (`packages/react-on-rails/src/`)

- **`ReactOnRails.ts`**: Main entry point for client-side functionality
- **`serverRenderReactComponent.ts`**: Server-side rendering logic
- **`ComponentRegistry.ts`**: Manages React component registration
- **`StoreRegistry.ts`**: Manages Redux store registration

### Build System

- **Ruby**: Standard gemspec-based build
- **JavaScript**: TypeScript compilation to `packages/react-on-rails/lib/`
- **Testing**: Jest for JS, RSpec for Ruby
- **Linting**: ESLint for JS/TS, RuboCop for Ruby

### Examples and Testing

- **Dummy app**: `spec/dummy/` - Rails app for testing integration
- **Examples**: Generated via rake tasks for different webpack configurations
- **Rake tasks**: Defined in `rakelib/` for various development operations

## Debugging Webpack Configuration Issues

When encountering issues with Webpack/Shakapacker configuration (e.g., components not rendering, CSS modules failing), use this debugging approach:

### 1. Create Debug Scripts

Create temporary debug scripts in the dummy app root to inspect the actual webpack configuration:

```javascript
// debug-webpack-rules.js - Inspect all webpack rules
const { generateWebpackConfig } = require('shakapacker');

const config = generateWebpackConfig();

console.log('=== Webpack Rules ===');
console.log(`Total rules: ${config.module.rules.length}\n`);

config.module.rules.forEach((rule, index) => {
  console.log(`\nRule ${index}:`);
  console.log('  test:', rule.test);
  console.log('  use:', Array.isArray(rule.use) ? rule.use.map(u => typeof u === 'string' ? u : u.loader) : rule.use);

  if (rule.test) {
    console.log('  Matches .scss:', rule.test.test && rule.test.test('example.scss'));
    console.log('  Matches .module.scss:', rule.test.test && rule.test.test('example.module.scss'));
  }
});
```

```javascript
// debug-webpack-with-config.js - Inspect config AFTER modifications
const commonWebpackConfig = require('./config/webpack/commonWebpackConfig');

const config = commonWebpackConfig();

console.log('=== Webpack Rules AFTER commonWebpackConfig ===');
config.module.rules.forEach((rule, index) => {
  if (rule.test && rule.test.test('example.module.scss')) {
    console.log(`\nRule ${index} (CSS Modules):`);
    if (Array.isArray(rule.use)) {
      rule.use.forEach((loader, i) => {
        if (loader.loader && loader.loader.includes('css-loader')) {
          console.log(`  css-loader options:`, loader.options);
        }
      });
    }
  }
});
```

### 2. Run Debug Scripts

```bash
cd spec/dummy  # or react_on_rails_pro/spec/dummy
NODE_ENV=test RAILS_ENV=test node debug-webpack-rules.js
NODE_ENV=test RAILS_ENV=test node debug-webpack-with-config.js
```

### 3. Analyze Output

- Verify the rules array structure matches expectations
- Check that loader options are correctly set
- Confirm rules only match intended file patterns
- Ensure modifications don't break existing loaders

### 4. Common Issues & Solutions

**CSS Modules breaking after Shakapacker upgrade:**
- Shakapacker 9.0+ defaults to `namedExport: true` for CSS Modules
- Existing code using `import styles from './file.module.css'` will fail
- Override in webpack config:
  ```javascript
  loader.options.modules.namedExport = false;
  loader.options.modules.exportLocalsConvention = 'camelCase';
  ```

**Rules not matching expected files:**
- Use `.test.test('example.file')` to check regex matching
- Shakapacker may combine multiple file extensions in single rules
- Test with actual filenames from your codebase

### 5. Clean Up

Always remove debug scripts before committing:
```bash
rm debug-*.js
```

## Important Notes

- Use `yalc` for local development when testing with external apps
- Server-side rendering uses isolated Node.js processes
- React Server Components support available in Pro version
- Generated examples are in `gen-examples/` (ignored by git)
- Only use `yarn` as the JS package manager, never `npm`

## IDE Configuration

Exclude these directories to prevent IDE slowdowns:

- `/coverage`, `/tmp`, `/gen-examples`, `/packages/react-on-rails/lib`
- `/node_modules`, `/spec/dummy/node_modules`, `/spec/dummy/tmp`
- `/spec/dummy/app/assets/webpack`, `/spec/dummy/log`
