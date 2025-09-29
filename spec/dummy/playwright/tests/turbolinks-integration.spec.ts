import { test, expect } from '@playwright/test';

test.describe('Turbolinks/Turbo Integration', () => {
  test('should handle Turbolinks navigation', async ({ page }) => {
    await page.goto('/');

    // Check if Turbolinks is loaded (if enabled)
    const hasTurbolinks = await page.evaluate(() => {
      return typeof (window as any).Turbolinks !== 'undefined';
    });

    if (hasTurbolinks) {
      console.log('Turbolinks is enabled - testing navigation');

      // Test that React components survive Turbolinks navigation
      // This would need actual navigation links in your app

      // Verify React on Rails components are still mounted
      const componentRegistry = await page.evaluate(() => {
        return typeof (window as any).ReactOnRails !== 'undefined';
      });
      expect(componentRegistry).toBeTruthy();
    }
  });

  test('should maintain React state across Turbo navigations', async ({ page }) => {
    await page.goto('/');

    // Set some state in a component
    const helloWorld = page.locator('#HelloWorld-react-component-1');
    const input = helloWorld.locator('input');
    await input.fill('Test State');

    // If there are navigation links, test them
    // This is a placeholder - you'd need actual navigation in your app
    const links = await page.locator('a[data-turbo]').count();
    if (links > 0) {
      // Click first turbo link
      await page.locator('a[data-turbo]').first().click();

      // Navigate back
      await page.goBack();

      // Check if component remounts properly
      await expect(page.locator('#HelloWorld-react-component-1')).toBeVisible();
    }
  });
});
