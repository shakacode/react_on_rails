import { test, expect } from '@playwright/test';
import { app } from '../../support/on-rails';

test.describe('React on Rails Basic Components', () => {
  test.beforeEach(async () => {
    await app('clean');
  });

  test('should render server-side rendered React component without Redux', async ({ page }) => {
    await page.goto('/');

    // Check for HelloWorld component
    const helloWorld = page.locator('#HelloWorld-react-component-1');
    await expect(helloWorld).toBeVisible();

    // Verify it has content
    const heading = helloWorld.locator('h3');
    await expect(heading).toBeVisible();
    await expect(heading).toContainText('Hello');
  });

  test('should render server-side rendered Redux component', async ({ page }) => {
    await page.goto('/');

    // Check for server-rendered Redux component
    const reduxApp = page.locator('#ReduxApp-react-component-0');
    await expect(reduxApp).toBeVisible();

    // Verify it has content
    const heading = reduxApp.locator('h3');
    await expect(heading).toBeVisible();
  });

  test('should handle client-side interactivity in React component', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Find the HelloWorld component
    const helloWorld = page.locator('#HelloWorld-react-component-1');

    // Find the input field and type a new name
    const input = helloWorld.locator('input');
    await input.clear();
    await input.fill('Playwright Test');

    // Verify the heading updates
    const heading = helloWorld.locator('h3');
    await expect(heading).toContainText('Playwright Test');
  });

  test('should handle Redux state changes', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Find the Redux app component
    const reduxApp = page.locator('#ReduxApp-react-component-0');

    // Interact with the input
    const input = reduxApp.locator('input');
    await input.clear();
    await input.fill('Redux with Playwright');

    // Verify the state change is reflected
    const heading = reduxApp.locator('h3');
    await expect(heading).toContainText('Redux with Playwright');
  });

  test('should have server-rendered content in initial HTML', async ({ page }) => {
    // Disable JavaScript to verify server rendering
    await page.route('**/*.js', (route) => route.abort());
    await page.goto('/');

    // Check that server-rendered components are visible even without JS
    const reduxApp = page.locator('#ReduxApp-react-component-0');
    await expect(reduxApp).toBeVisible();

    // The content should be present
    const heading = reduxApp.locator('h3');
    await expect(heading).toBeVisible();
  });

  test('should properly hydrate server-rendered components', async ({ page }) => {
    await page.goto('/');

    // Wait for hydration
    await page.waitForLoadState('networkidle');

    // Check that components are interactive after hydration
    const helloWorld = page.locator('#HelloWorld-react-component-1');
    const input = helloWorld.locator('input');

    // Should be able to interact with the input
    await expect(input).toBeEnabled();
    await input.fill('Hydrated Component');

    // Check the update works
    const heading = helloWorld.locator('h3');
    await expect(heading).toContainText('Hydrated Component');
  });

  test('should not have console errors on page load', async ({ page }) => {
    const consoleErrors = [];

    // Listen for console errors
    page.on('console', (message) => {
      if (message.type() === 'error') {
        // Filter out known non-issues
        const text = message.text();
        if (
          !text.includes('Download the React DevTools') &&
          !text.includes('SharedArrayBuffer will require cross-origin isolation') &&
          !text.includes('immediate_hydration')
        ) {
          consoleErrors.push(text);
        }
      }
    });

    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Check that no unexpected errors occurred
    expect(consoleErrors).toHaveLength(0);
  });
});
