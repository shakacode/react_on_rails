# Playwright E2E Tests for React on Rails

This directory contains end-to-end tests for React on Rails using Playwright.

## Quick Start

```bash
# Install dependencies
yarn install

# Install Playwright browsers
yarn playwright install --with-deps

# Run tests
yarn test:e2e

# Run tests in UI mode for debugging
yarn test:e2e:ui
```

## Test Structure

```
playwright/
├── tests/                      # Test files
│   ├── basic-react-components.spec.ts
│   ├── turbolinks-integration.spec.ts
│   ├── error-handling.spec.ts
│   └── performance.spec.ts
├── fixtures/                   # Test helpers and utilities
│   └── test-helpers.ts
└── README.md
```

## Available Commands

- `yarn test:e2e` - Run all tests in headless mode
- `yarn test:e2e:ui` - Open Playwright UI for interactive testing
- `yarn test:e2e:debug` - Run tests in debug mode
- `yarn test:e2e:headed` - Run tests with visible browser
- `yarn test:e2e:report` - Show HTML report of last test run

## Writing Tests

Tests should focus on:

1. **Component Rendering** - Verify React components render correctly
2. **Interactivity** - Test user interactions and state changes
3. **Server Rendering** - Ensure SSR works properly
4. **Hydration** - Verify client-side hydration of server-rendered content
5. **Integration** - Test with Rails features like Turbolinks/Turbo

Example test:

```typescript
import { test, expect } from '@playwright/test';

test('should interact with React component', async ({ page }) => {
  await page.goto('/');

  const component = page.locator('#HelloWorld-react-component-1');
  const input = component.locator('input');

  await input.fill('Test Input');
  await expect(component.locator('h3')).toContainText('Test Input');
});
```

## Custom Helpers

The `fixtures/test-helpers.ts` file provides utilities for React on Rails testing:

- `waitForHydration()` - Wait for client-side hydration to complete
- `getServerRenderedData()` - Extract server-rendered props/data
- `expectNoConsoleErrors()` - Assert no console errors occurred

## Configuration

Configuration is in `playwright.config.ts`:

- Tests multiple browsers (Chrome, Firefox, Safari)
- Includes mobile viewports
- Auto-starts Rails server
- Generates HTML reports
- Takes screenshots on failure

## CI Integration

Tests run automatically in GitHub Actions. The workflow:

1. Sets up Ruby/Node environments
2. Installs dependencies
3. Builds assets
4. Runs Playwright tests
5. Uploads test reports

## Debugging

When tests fail:

1. Run `yarn test:e2e:ui` for interactive debugging
2. Check `playwright-report/` for detailed results
3. Use `page.pause()` to pause execution
4. Enable traces in config for detailed debugging

## Best Practices

1. **Use proper selectors** - Target React on Rails component IDs
2. **Wait for hydration** - Ensure components are interactive
3. **Test across browsers** - Run tests in all configured browsers
4. **Clean state** - Each test should be independent
5. **Monitor console** - Check for JavaScript errors
6. **Test SSR** - Verify server rendering works without JavaScript
