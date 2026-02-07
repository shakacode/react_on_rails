# Playwright E2E Testing

## Overview

Playwright E2E testing is integrated via the `cypress-on-rails` gem (v1.19+), which provides seamless integration between Playwright and Rails. This allows you to control Rails application state during tests, use factory_bot, and more.

## Setup

The gem and Playwright are already configured. To install Playwright browsers:

```bash
cd react_on_rails/spec/dummy
pnpm playwright install --with-deps
```

## Running Playwright Tests

**Note:** Playwright will automatically start the Rails server on port 5017 before running tests. You don't need to manually start the server.

```bash
cd react_on_rails/spec/dummy

# Run all tests (Rails server auto-starts)
pnpm test:e2e

# Run tests in UI mode (interactive debugging)
pnpm test:e2e:ui

# Run tests with visible browser
pnpm test:e2e:headed

# Debug a specific test
pnpm test:e2e:debug

# View test report
pnpm test:e2e:report

# Run specific test file
pnpm test:e2e e2e/playwright/e2e/react_on_rails/basic_components.spec.js
```

## Writing Tests

Tests are located in `react_on_rails/spec/dummy/e2e/playwright/e2e/`. The gem provides helpful commands for Rails integration:

```javascript
import { test, expect } from '@playwright/test';
import { app, appEval, appFactories } from '../../support/on-rails';

test.describe('My React Component', () => {
  test.beforeEach(async ({ page }) => {
    // Clean database before each test
    await app('clean');
  });

  test('should interact with component', async ({ page }) => {
    // Create test data using factory_bot
    await appFactories([['create', 'user', { name: 'Test User' }]]);

    // Or run arbitrary Ruby code
    await appEval('User.create!(email: "test@example.com")');

    // Navigate and test
    await page.goto('/');
    const component = page.locator('#MyComponent-react-component-0');
    await expect(component).toBeVisible();
  });
});
```

## Available Rails Helpers

The `cypress-on-rails` gem provides these helpers (imported from `support/on-rails.js`):

- `app('clean')` - Clean database
- `appEval(code)` - Run arbitrary Ruby code
- `appFactories(options)` - Create records via factory_bot
- `appScenario(name)` - Load predefined scenario
- See `e2e/playwright/app_commands/` for available commands

## Creating App Commands

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

## Test Organization

```
react_on_rails/spec/dummy/e2e/
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

## Best Practices

- Use `app('clean')` in `beforeEach` to ensure clean state
- Leverage Rails helpers (`appFactories`, `appEval`) instead of UI setup
- Test React on Rails specific features: SSR, hydration, component registry
- Use component IDs like `#ComponentName-react-component-0` for selectors
- Monitor console errors during tests
- Test across different browsers with `--project` flag

## Debugging

- Run in UI mode: `pnpm test:e2e:ui`
- Use `page.pause()` to pause execution
- Check `playwright-report/` for detailed results after test failures
- Enable debug logging in `playwright.config.js`

## CI Integration

Playwright E2E tests run via GitHub Actions (`.github/workflows/playwright.yml`). The workflow:

- **Only runs on pushes to master and manual dispatch (workflow_dispatch)**
- Does NOT automatically run on PRs
- Uses GitHub Actions annotations for test failures
- Uploads HTML reports as artifacts (available for 30 days)
- Auto-starts Rails server before running tests

## Ensuring E2E Tests Pass Before Merging

**CRITICAL: Playwright E2E tests do NOT run automatically on PRs. You must run them locally or trigger manually.**

1. **Run tests locally BEFORE pushing your PR:**

   ```bash
   cd react_on_rails/spec/dummy
   pnpm test:e2e
   ```

2. **If you need to verify on CI, manually trigger the workflow:**

   ```bash
   # Trigger workflow on your branch
   gh workflow run "Playwright E2E Tests" --ref your-branch-name

   # Monitor the run
   gh run watch
   ```

3. **Download test artifacts if tests fail:**

   ```bash
   # List artifacts from a failed run
   gh run view <run-id> --json jobs

   # Download playwright report
   gh run download <run-id> -n playwright-report
   ```

**DO NOT merge PRs without running Playwright tests.** The CI does not automatically run these tests on PRs - you must verify locally or trigger manually.
