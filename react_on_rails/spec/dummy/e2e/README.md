# Playwright E2E Tests for React on Rails

This directory contains end-to-end tests using Playwright integrated with Rails via the `cypress-on-rails` gem.

## Quick Start

```bash
# Install Playwright browsers (first time only)
pnpm playwright install --with-deps

# Run all tests
pnpm test:e2e

# Run in UI mode for debugging
pnpm test:e2e:ui
```

## Features

The `cypress-on-rails` gem provides seamless integration between Playwright and Rails:

- **Database Control**: Clean/reset database between tests
- **Factory Bot Integration**: Create test data easily
- **Run Ruby Code**: Execute arbitrary Ruby code from tests
- **Scenarios**: Load predefined application states
- **No UI Setup Needed**: Set up test data via Rails instead of clicking through UI

## Test Organization

```
e2e/
├── playwright.config.js          # Playwright configuration
└── playwright/
    ├── support/
    │   ├── index.js              # Test setup
    │   └── on-rails.js           # Rails helper functions
    ├── e2e/
    │   ├── react_on_rails/       # React on Rails tests
    │   │   └── basic_components.spec.js
    │   └── rails_examples/       # Example tests
    │       └── using_scenarios.spec.js
    └── app_commands/             # Rails commands callable from tests
        ├── clean.rb              # Database cleanup
        ├── factory_bot.rb        # Factory bot integration
        ├── eval.rb               # Run arbitrary Ruby
        └── scenarios/
            └── basic.rb          # Predefined scenarios
```

## Writing Tests

### Basic Test Structure

```javascript
import { test, expect } from '@playwright/test';
import { app } from '../../support/on-rails';

test.describe('My Feature', () => {
  test.beforeEach(async ({ page }) => {
    // Clean database before each test
    await app('clean');
  });

  test('should do something', async ({ page }) => {
    await page.goto('/');
    // Your test code here
  });
});
```

### Using Rails Helpers

```javascript
import { app, appEval, appFactories, appScenario } from '../../support/on-rails';

// Clean database
await app('clean');

// Run arbitrary Ruby code
await appEval('User.create!(email: "test@example.com")');

// Use factory_bot
await appFactories([
  ['create', 'user', { name: 'Test User' }],
  ['create_list', 'post', 3],
]);

// Load a predefined scenario
await appScenario('basic');
```

### Testing React on Rails Components

```javascript
test('should interact with React component', async ({ page }) => {
  await page.goto('/');

  // Target component by ID (React on Rails naming convention)
  const component = page.locator('#HelloWorld-react-component-1');
  await expect(component).toBeVisible();

  // Test interactivity
  const input = component.locator('input');
  await input.fill('New Value');

  const heading = component.locator('h3');
  await expect(heading).toContainText('New Value');
});
```

### Testing Server-Side Rendering

```javascript
test('should have server-rendered content', async ({ page }) => {
  // Disable JavaScript to verify SSR
  await page.route('**/*.js', (route) => route.abort());
  await page.goto('/');

  // Component should still be visible
  const component = page.locator('#ReduxApp-react-component-0');
  await expect(component).toBeVisible();
});
```

## Available Commands

### Default Commands (in `app_commands/`)

- `clean` - Clean/reset database
- `eval` - Run arbitrary Ruby code
- `factory_bot` - Create records via factory_bot
- `scenarios/{name}` - Load predefined scenario

### Custom Commands

Create new commands in `playwright/app_commands/`:

```ruby
# app_commands/my_command.rb
command 'my_command' do |options|
  # Your Rails code here
  { success: true, data: options }
end
```

Use in tests:

```javascript
await app('my_command', { some: 'options' });
```

## Running Tests

```bash
# All tests
pnpm test:e2e

# Specific file
pnpm test:e2e e2e/playwright/e2e/react_on_rails/basic_components.spec.js

# UI mode (interactive)
pnpm test:e2e:ui

# Headed mode (visible browser)
pnpm test:e2e:headed

# Debug mode
pnpm test:e2e:debug

# Specific browser
pnpm test:e2e --project=chromium
pnpm test:e2e --project=firefox
pnpm test:e2e --project=webkit

# View last run report
pnpm test:e2e:report
```

## Debugging

1. **UI Mode**: `pnpm test:e2e:ui` - Best for interactive debugging
2. **Headed Mode**: `pnpm test:e2e:headed` - See browser actions
3. **Pause Execution**: Add `await page.pause()` in your test
4. **Console Logging**: Check browser console in headed mode
5. **Screenshots**: Automatically taken on failure
6. **Test Reports**: Check `e2e/playwright-report/` after test run

## Best Practices

1. **Clean State**: Always use `await app('clean')` in `beforeEach`
2. **Use Rails Helpers**: Prefer `appEval`/`appFactories` over UI setup
3. **Component Selectors**: Use React on Rails component IDs (`#ComponentName-react-component-N`)
4. **Test SSR**: Verify components work without JavaScript
5. **Test Hydration**: Ensure client-side hydration works correctly
6. **Monitor Console**: Listen for console errors during tests
7. **Scenarios for Complex Setup**: Create reusable scenarios for complex application states

## More Information

- [Playwright Documentation](https://playwright.dev/)
- [cypress-on-rails Gem](https://github.com/shakacode/cypress-on-rails)
- [React on Rails Testing Guide](../../CLAUDE.md#playwright-e2e-testing)
