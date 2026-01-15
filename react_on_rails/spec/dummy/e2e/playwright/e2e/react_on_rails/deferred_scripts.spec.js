/**
 * Deferred Script Race Condition Tests (PR #1773 Regression Test)
 *
 * These tests validate that React on Rails correctly handles deferred script loading.
 *
 * The Bug (fixed):
 * When using <script defer>, the browser timeline is:
 *   1. Browser parses HTML
 *   2. readyState becomes 'interactive' (DOM parsed, but deferred scripts may not have run)
 *   3. Deferred scripts execute (ReactOnRails.register() is called here)
 *   4. DOMContentLoaded event fires
 *   5. readyState becomes 'complete'
 *
 * The old code checked `readyState !== 'loading'`, which includes 'interactive'.
 * This caused React on Rails to attempt hydration at step 2, before components were
 * registered at step 3, resulting in "Could not find component registered with name" errors.
 *
 * The fix: Check `readyState === 'complete'` or wait for DOMContentLoaded, ensuring
 * we don't hydrate until after deferred scripts have executed.
 */

import { test, expect } from '@playwright/test';
import { app } from '../../support/on-rails';

test.describe('Deferred Script Loading (PR #1773 regression test)', () => {
  test.beforeEach(async () => {
    await app('clean');
  });

  test('should render components without "Could not find component" errors when using defer scripts', async ({
    page,
  }) => {
    // Track console errors, specifically looking for the race condition error
    const consoleErrors = [];
    const componentNotFoundErrors = [];

    page.on('console', (message) => {
      if (message.type() === 'error') {
        const text = message.text();
        consoleErrors.push(text);

        // Specifically track the error that indicates the race condition
        if (text.includes('Could not find component registered with name')) {
          componentNotFoundErrors.push(text);
        }
      }
    });

    // Load the root page which uses deferred scripts (see layout: defer: true)
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // The critical assertion: no "component not found" errors should occur
    expect(componentNotFoundErrors).toHaveLength(0);

    // Components should be visible and rendered
    const reduxApp = page.locator('#ReduxApp-react-component-0');
    await expect(reduxApp).toBeVisible();

    const helloWorld = page.locator('#HelloWorld-react-component-1');
    await expect(helloWorld).toBeVisible();
  });

  test('should work correctly even when JavaScript bundle is delayed (stress test)', async ({ page }) => {
    // Track the race condition error specifically
    const componentNotFoundErrors = [];

    page.on('console', (message) => {
      if (message.type() === 'error') {
        const text = message.text();
        if (text.includes('Could not find component registered with name')) {
          componentNotFoundErrors.push(text);
        }
      }
    });

    // Intercept the JavaScript bundle and delay it by 500ms
    // This simulates slow network conditions that would make the race condition more likely
    // to trigger if the fix wasn't in place
    await page.route('**/client-bundle*.js', async (route) => {
      // Add artificial delay before continuing with the request
      await new Promise((resolve) => {
        setTimeout(resolve, 500);
      });
      await route.continue();
    });

    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Even with delayed scripts, no race condition errors should occur
    expect(componentNotFoundErrors).toHaveLength(0);

    // Components should still render and hydrate correctly
    const reduxApp = page.locator('#ReduxApp-react-component-0');
    await expect(reduxApp).toBeVisible();
  });

  test('should maintain client-side interactivity after delayed script loading', async ({ page }) => {
    // Add delay to script loading
    await page.route('**/client-bundle*.js', async (route) => {
      await new Promise((resolve) => {
        setTimeout(resolve, 300);
      });
      await route.continue();
    });

    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Find the HelloWorld component and verify it's interactive
    const helloWorld = page.locator('#HelloWorld-react-component-1');
    await expect(helloWorld).toBeVisible();

    // Type in the input field to verify hydration worked
    const input = helloWorld.locator('input');
    await expect(input).toBeEnabled();
    await input.clear();
    await input.fill('Delayed Script Test');

    // Verify the component updates (proves hydration was successful)
    const heading = helloWorld.locator('h3');
    await expect(heading).toContainText('Delayed Script Test');
  });

  test('server-rendered page with defer scripts should work correctly', async ({ page }) => {
    const componentNotFoundErrors = [];

    page.on('console', (message) => {
      if (message.type() === 'error') {
        const text = message.text();
        if (text.includes('Could not find component registered with name')) {
          componentNotFoundErrors.push(text);
        }
      }
    });

    // Test a server-side rendered page that uses deferred scripts
    await page.goto('/server_side_hello_world');
    await page.waitForLoadState('networkidle');

    // No race condition errors
    expect(componentNotFoundErrors).toHaveLength(0);

    // Server-rendered component should be visible
    const component = page.locator('[id^="HelloWorld"]');
    await expect(component.first()).toBeVisible();
  });

  test('client-side only page with defer scripts should work correctly', async ({ page }) => {
    const componentNotFoundErrors = [];

    page.on('console', (message) => {
      if (message.type() === 'error') {
        const text = message.text();
        if (text.includes('Could not find component registered with name')) {
          componentNotFoundErrors.push(text);
        }
      }
    });

    // Test a client-side only rendered page
    await page.goto('/client_side_hello_world');
    await page.waitForLoadState('networkidle');

    // No race condition errors
    expect(componentNotFoundErrors).toHaveLength(0);

    // Client-rendered component should be visible after hydration
    const component = page.locator('[id^="HelloWorld"]');
    await expect(component.first()).toBeVisible();
  });
});
