import { test, expect } from '@playwright/test';
import { app } from '../../support/on-rails';

/**
 * Tests for Issue #2210: Hydration mismatch when reactOnRailsPageLoaded() is called multiple times
 *
 * When a user calls ReactOnRails.reactOnRailsPageLoaded() multiple times (e.g., for asynchronously
 * loaded content), the previously rendered client-side components should NOT be re-hydrated.
 * This was causing hydration mismatch errors because React was trying to hydrate components
 * that were already rendered on the client (not server-rendered).
 *
 * The fix: Skip rendering for components that are already tracked in the renderedRoots Map.
 */
test.describe('Issue #2210: reactOnRailsPageLoaded() Multiple Calls', () => {
  test.beforeEach(async () => {
    await app('clean');
  });

  test('should render client-side component without errors on initial load', async ({ page }) => {
    const consoleErrors = [];

    page.on('console', (message) => {
      if (message.type() === 'error') {
        const text = message.text();
        // Capture hydration-related errors
        if (text.toLowerCase().includes('hydrat')) {
          consoleErrors.push(text);
        }
      }
    });

    await page.goto('/async_page_loaded_test');
    await page.waitForLoadState('networkidle');

    // Verify the first component rendered
    const firstComponent = page.locator('#AsyncComponent-1');
    await expect(firstComponent).toBeVisible();

    // Check for the component content
    const componentText = firstComponent.locator('[data-testid="async-component"]');
    await expect(componentText).toContainText('First Component');

    // No hydration errors should occur on initial load
    expect(consoleErrors).toHaveLength(0);
  });

  test('should NOT cause hydration errors when reactOnRailsPageLoaded() is called again', async ({
    page,
  }) => {
    const consoleErrors = [];
    const consoleLogs = [];

    page.on('console', (message) => {
      const text = message.text();
      if (message.type() === 'error') {
        // Capture any hydration-related errors
        if (
          text.toLowerCase().includes('hydrat') ||
          text.toLowerCase().includes('did not match') ||
          text.toLowerCase().includes('mismatch')
        ) {
          consoleErrors.push(text);
        }
      }
      if (message.type() === 'log') {
        consoleLogs.push(text);
      }
    });

    await page.goto('/async_page_loaded_test');
    await page.waitForLoadState('networkidle');

    // Verify initial component is rendered
    const firstComponent = page.locator('#AsyncComponent-1');
    await expect(firstComponent).toBeVisible();

    // Click the button to add a new component and trigger reactOnRailsPageLoaded()
    const addButton = page.locator('#add-component-btn');
    await addButton.click();

    // Wait for the new component to be rendered
    const secondComponent = page.locator('#AsyncComponent-2');
    await expect(secondComponent).toBeVisible();

    // Verify the second component has content
    await expect(secondComponent.locator('[data-testid="async-component"]')).toContainText(
      'Dynamic Component #2',
    );

    // Check that reactOnRailsPageLoaded was called
    const pageLoadedCalled = consoleLogs.some((log) => log.includes('Calling reactOnRailsPageLoaded'));
    expect(pageLoadedCalled).toBe(true);

    // CRITICAL: No hydration errors should have occurred
    // This is the main test for Issue #2210
    expect(consoleErrors).toHaveLength(0);

    // First component should still be visible and functional
    await expect(firstComponent).toBeVisible();
    await expect(firstComponent.locator('[data-testid="async-component"]')).toContainText('First Component');
  });

  test('should handle multiple dynamic component additions without hydration errors', async ({ page }) => {
    const consoleErrors = [];

    page.on('console', (message) => {
      const text = message.text();
      if (message.type() === 'error') {
        if (
          text.toLowerCase().includes('hydrat') ||
          text.toLowerCase().includes('did not match') ||
          text.toLowerCase().includes('mismatch')
        ) {
          consoleErrors.push(text);
        }
      }
    });

    await page.goto('/async_page_loaded_test');
    await page.waitForLoadState('networkidle');

    const addButton = page.locator('#add-component-btn');

    // Add 3 components dynamically (components 2, 3, 4)
    await addButton.click();
    await expect(page.locator('#AsyncComponent-2')).toBeVisible();
    await expect(page.locator('#AsyncComponent-2').locator('[data-testid="async-component"]')).toContainText(
      'Dynamic Component #2',
    );

    await addButton.click();
    await expect(page.locator('#AsyncComponent-3')).toBeVisible();
    await expect(page.locator('#AsyncComponent-3').locator('[data-testid="async-component"]')).toContainText(
      'Dynamic Component #3',
    );

    await addButton.click();
    await expect(page.locator('#AsyncComponent-4')).toBeVisible();
    await expect(page.locator('#AsyncComponent-4').locator('[data-testid="async-component"]')).toContainText(
      'Dynamic Component #4',
    );

    // All 4 components should be visible (1 initial + 3 added)
    await expect(page.locator('[data-testid="async-component"]')).toHaveCount(4);

    // CRITICAL: No hydration errors should have occurred during any of the additions
    expect(consoleErrors).toHaveLength(0);
  });

  test('should show success message in test results div', async ({ page }) => {
    await page.goto('/async_page_loaded_test');
    await page.waitForLoadState('networkidle');

    // Click to add a component
    const addButton = page.locator('#add-component-btn');
    await addButton.click();

    // Wait for component to render
    await expect(page.locator('#AsyncComponent-2')).toBeVisible();

    // Check the test results div for success message
    const resultsDiv = page.locator('#test-results');
    await expect(resultsDiv).toContainText('No hydration errors detected');
  });
});
