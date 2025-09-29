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

**Note:** Git hooks are for React on Rails gem developers only, not for users who install the gem.

## Development Commands

### Essential Commands

- **Install dependencies**: `bundle && yarn`
- **Run tests**:
  - Ruby tests: `rake run_rspec`
  - JavaScript tests: `yarn run test` or `rake js_tests`
  - Playwright E2E tests: `yarn test:e2e` (see Playwright section below)
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
- Never run `npm` commands, only equivalent Yarn Classic ones

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
- Server-side rendering uses isolated Node.js processes
- React Server Components support available in Pro version
- Generated examples are in `gen-examples/` (ignored by git)
- Only use `yarn` as the JS package manager, never `npm`

## Playwright E2E Testing

### Overview
Playwright provides cross-browser end-to-end testing for React on Rails components. Tests run against a real Rails server with compiled assets, ensuring components work correctly in production-like conditions.

### Setup and Installation
```bash
# Install Playwright and its dependencies
yarn add -D @playwright/test
yarn playwright install --with-deps  # Install browsers

# Or just install specific browsers
yarn playwright install chromium
```

### Running Playwright Tests
```bash
# Navigate to dummy app
cd spec/dummy

# Run all tests
yarn test:e2e

# Run tests in UI mode (interactive)
yarn test:e2e:ui

# Run tests with visible browser (headed mode)
yarn test:e2e:headed

# Debug tests
yarn test:e2e:debug

# View test report
yarn test:e2e:report

# Run specific test file
yarn playwright test playwright/tests/basic-react-components.spec.ts

# Run tests in specific browser
yarn playwright test --project=chromium
yarn playwright test --project=firefox
yarn playwright test --project=webkit
```

### Writing Playwright Tests
Tests are located in `spec/dummy/playwright/tests/` directory. Example:

```typescript
import { test, expect } from '@playwright/test';

test('React component interaction', async ({ page }) => {
  await page.goto('/');
  
  // Find React on Rails component
  const component = page.locator('#HelloWorld-react-component-1');
  await expect(component).toBeVisible();
  
  // Interact with component
  const input = component.locator('input');
  await input.fill('Playwright Test');
  
  // Verify state change
  const heading = component.locator('h3');
  await expect(heading).toContainText('Playwright Test');
});
```

### Test Helpers
Custom test helpers are available in `spec/dummy/playwright/fixtures/test-helpers.ts`:
- `waitForHydration()` - Wait for React on Rails components to hydrate
- `getServerRenderedData()` - Extract server-rendered component data
- `expectNoConsoleErrors()` - Verify no console errors occur

### Configuration
Configuration is in `spec/dummy/playwright.config.ts`:
- Base URL: `http://localhost:3000`
- Browsers: Chrome, Firefox, Safari, Mobile Chrome, Mobile Safari
- Server: Automatically starts Rails server before tests
- Reports: HTML reports for local, GitHub reports for CI

### Continuous Integration
Playwright tests run automatically in GitHub Actions on PRs and pushes to main branch. The workflow:
1. Sets up Ruby and Node environments
2. Installs dependencies
3. Compiles assets
4. Sets up database
5. Runs Playwright tests
6. Uploads test reports as artifacts

### Best Practices
- Always wait for React on Rails components to mount/hydrate before interactions
- Use component-specific selectors (e.g., `#ComponentName-react-component-N`)
- Test both server-rendered and client-rendered components
- Include tests for Turbolinks/Turbo integration if enabled
- Monitor console errors and network failures
- Test across different browsers and viewports

### Debugging Tips
- Use `page.pause()` to pause execution in headed mode
- Enable `trace: 'on'` in config for detailed traces
- Use `--debug` flag to step through tests
- Check `playwright-report/` for detailed test results
- Use UI mode (`yarn test:e2e:ui`) for interactive debugging

## IDE Configuration

Exclude these directories to prevent IDE slowdowns:

- `/coverage`, `/tmp`, `/gen-examples`, `/node_package/lib`
- `/node_modules`, `/spec/dummy/node_modules`, `/spec/dummy/tmp`
- `/spec/dummy/app/assets/webpack`, `/spec/dummy/log`
- `/playwright-report`, `/test-results`
