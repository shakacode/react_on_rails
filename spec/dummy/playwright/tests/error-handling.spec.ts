import { test, expect } from '@playwright/test';

test.describe('Error Handling and Console Monitoring', () => {
  test('should not have console errors on page load', async ({ page }) => {
    const consoleErrors: string[] = [];

    // Listen for console errors
    page.on('console', (message) => {
      if (message.type() === 'error') {
        // Filter out known non-issues
        const text = message.text();
        if (
          !text.includes('Download the React DevTools') &&
          !text.includes('SharedArrayBuffer will require cross-origin isolation')
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

  test('should handle component errors gracefully', async ({ page }) => {
    await page.goto('/');

    // Try to trigger an error by providing invalid input
    // This test assumes your components have error boundaries
    const helloWorld = page.locator('#HelloWorld-react-component-1');
    const input = helloWorld.locator('input');

    // Type a very long string to test boundaries
    const longString = 'a'.repeat(1000);
    await input.fill(longString);

    // Component should still be visible and functional
    await expect(helloWorld).toBeVisible();
    const heading = helloWorld.locator('h3');
    await expect(heading).toBeVisible();
  });

  test('should track JavaScript errors', async ({ page }) => {
    const jsErrors: Error[] = [];

    page.on('pageerror', (error) => {
      jsErrors.push(error);
    });

    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Verify no JavaScript errors occurred
    expect(jsErrors).toHaveLength(0);
  });

  test('should handle network errors gracefully', async ({ page }) => {
    // Intercept API calls and simulate failures
    await page.route('**/api/**', (route) => {
      route.abort('failed');
    });

    await page.goto('/');

    // Page should still load even if API calls fail
    await expect(page.locator('#ReduxApp-react-component-0')).toBeVisible();
  });
});
