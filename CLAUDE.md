# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## ⚠️ CRITICAL REQUIREMENTS

**BEFORE EVERY COMMIT/PUSH:**

1. **ALWAYS run `bundle exec rubocop` and fix ALL violations**
2. **ALWAYS ensure files end with a newline character**
3. **NEVER push without running full lint check first**
4. **ALWAYS let Prettier handle ALL formatting - never manually format**

These requirements are non-negotiable. CI will fail if not followed.

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
- **Build**: `yarn run build` (compiles TypeScript to JavaScript in node_package/lib)
- **Type checking**: `yarn run type-check`
- **⚠️ MANDATORY BEFORE GIT PUSH**: `bundle exec rubocop` and fix ALL violations + ensure trailing newlines

## ⚠️ FORMATTING RULES

**Prettier is the SOLE authority for formatting. NEVER manually format code.**

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

### Dual Package Structure

This project maintains both a Ruby gem and an NPM package:

- **Ruby gem**: Located in `lib/`, provides Rails integration and server-side rendering
- **NPM package**: Located in `node_package/src/`, provides client-side React integration

### Core Components

#### Ruby Side (`lib/react_on_rails/`)

- **`helper.rb`**: Rails view helpers for rendering React components
- **`server_rendering_pool.rb`**: Manages Node.js processes for server-side rendering
- **`configuration.rb`**: Global configuration management
- **`engine.rb`**: Rails engine integration
- **Generators**: Located in `lib/generators/react_on_rails/`

#### JavaScript/TypeScript Side (`node_package/src/`)

- **`ReactOnRails.ts`**: Main entry point for client-side functionality
- **`serverRenderReactComponent.ts`**: Server-side rendering logic
- **`ComponentRegistry.ts`**: Manages React component registration
- **`StoreRegistry.ts`**: Manages Redux store registration

### Build System

- **Ruby**: Standard gemspec-based build
- **JavaScript**: TypeScript compilation to `node_package/lib/`
- **Testing**: Jest for JS, RSpec for Ruby
- **Linting**: ESLint for JS/TS, RuboCop for Ruby

### Examples and Testing

- **Dummy app**: `spec/dummy/` - Rails app for testing integration
- **Examples**: Generated via rake tasks for different webpack configurations
- **Rake tasks**: Defined in `rakelib/` for various development operations

## Important Notes

- Use `yalc` for local development when testing with external apps
- The project supports both Webpacker and Shakapacker
- Server-side rendering uses isolated Node.js processes
- React Server Components support available in Pro version
- Generated examples are in `gen-examples/` (ignored by git)

## IDE Configuration

Exclude these directories to prevent IDE slowdowns:

- `/coverage`, `/tmp`, `/gen-examples`, `/node_package/lib`
- `/node_modules`, `/spec/dummy/node_modules`, `/spec/dummy/tmp`
- `/spec/dummy/app/assets/webpack`, `/spec/dummy/log`
