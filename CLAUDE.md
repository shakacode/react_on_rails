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
  - Playwright E2E tests: See Playwright section below
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
- **NPM package**: Located in `packages/react-on-rails/src/`, provides client-side React integration

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

## Important Notes

- Use `yalc` for local development when testing with external apps
- Server-side rendering uses isolated Node.js processes
- React Server Components support available in Pro version
- Generated examples are in `gen-examples/` (ignored by git)
- Only use `yarn` as the JS package manager, never `npm`

## Playwright E2E Testing

### Overview
Playwright E2E testing is integrated via the `cypress-on-rails` gem (v1.19+), which provides seamless integration between Playwright and Rails. This allows you to control Rails application state during tests, use factory_bot, and more.

### Setup
The gem and Playwright are already configured. To install Playwright browsers:

```bash
cd spec/dummy
yarn playwright install --with-deps
```

### Running Playwright Tests

```bash
cd spec/dummy

# Run all tests
yarn playwright test

# Run tests in UI mode (interactive debugging)
yarn playwright test --ui

# Run tests with visible browser
yarn playwright test --headed

# Debug a specific test
yarn playwright test --debug

# Run specific test file
yarn playwright test e2e/playwright/e2e/react_on_rails/basic_components.spec.js
```

### Writing Tests

Tests are located in `spec/dummy/e2e/playwright/e2e/`. The gem provides helpful commands for Rails integration:

```javascript
import { test, expect } from "@playwright/test";
import { app, appEval, appFactories } from '../../support/on-rails';

test.describe("My React Component", () => {
  test.beforeEach(async ({ page }) => {
    // Clean database before each test
    await app('clean');
  });

  test("should interact with component", async ({ page }) => {
    // Create test data using factory_bot
    await appFactories([['create', 'user', { name: 'Test User' }]]);

    // Or run arbitrary Ruby code
    await appEval('User.create!(email: "test@example.com")');

    // Navigate and test
    await page.goto("/");
    const component = page.locator('#MyComponent-react-component-0');
    await expect(component).toBeVisible();
  });
});
```

### Available Rails Helpers

The `cypress-on-rails` gem provides these helpers (imported from `support/on-rails.js`):

- `app('clean')` - Clean database
- `appEval(code)` - Run arbitrary Ruby code
- `appFactories(options)` - Create records via factory_bot
- `appScenario(name)` - Load predefined scenario
- See `e2e/playwright/app_commands/` for available commands

### Creating App Commands

Add custom commands in `e2e/playwright/app_commands/`:

```ruby
# e2e/playwright/app_commands/my_command.rb
CypressOnRails::SmartFactoryWrapper.configure(
  always_reload: !Rails.configuration.cache_classes,
  factory: :factory_bot,
  dir: "{#{FactoryBot.definition_file_paths.join(',')}}"
)

command 'my_command' do |options|
  # Your custom Rails code
  { success: true, data: options }
end
```

### Test Organization

```
spec/dummy/e2e/
├── playwright.config.js          # Playwright configuration
├── playwright/
│   ├── support/
│   │   ├── index.js              # Test setup
│   │   └── on-rails.js           # Rails helper functions
│   ├── e2e/
│   │   ├── react_on_rails/       # React on Rails specific tests
│   │   │   └── basic_components.spec.js
│   │   └── rails_examples/       # Example tests
│   │       └── using_scenarios.spec.js
│   └── app_commands/             # Rails helper commands
│       ├── clean.rb
│       ├── factory_bot.rb
│       ├── eval.rb
│       └── scenarios/
│           └── basic.rb
```

### Best Practices

- Use `app('clean')` in `beforeEach` to ensure clean state
- Leverage Rails helpers (`appFactories`, `appEval`) instead of UI setup
- Test React on Rails specific features: SSR, hydration, component registry
- Use component IDs like `#ComponentName-react-component-0` for selectors
- Monitor console errors during tests
- Test across different browsers with `--project` flag

### Debugging

- Run in UI mode: `yarn playwright test --ui`
- Use `page.pause()` to pause execution
- Check `playwright-report/` for detailed results after test failures
- Enable debug logging in `playwright.config.js`

## IDE Configuration

Exclude these directories to prevent IDE slowdowns:

- `/coverage`, `/tmp`, `/gen-examples`, `/packages/react-on-rails/lib`
- `/node_modules`, `/spec/dummy/node_modules`, `/spec/dummy/tmp`
- `/spec/dummy/app/assets/webpack`, `/spec/dummy/log`
- `/spec/dummy/e2e/playwright-report`, `/spec/dummy/test-results`
