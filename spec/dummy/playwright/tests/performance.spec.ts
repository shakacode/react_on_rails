import { test, expect } from '@playwright/test';

test.describe('Performance Tests', () => {
  test('should load page within acceptable time', async ({ page }) => {
    const startTime = Date.now();

    await page.goto('/');
    await page.waitForLoadState('networkidle');

    const loadTime = Date.now() - startTime;

    // Page should load within 3 seconds
    expect(loadTime).toBeLessThan(3000);
  });

  test('should have acceptable Time to Interactive', async ({ page }) => {
    await page.goto('/');

    // Measure when the main component becomes interactive
    const startTime = Date.now();

    const input = page.locator('#HelloWorld-react-component-1 input');
    await input.waitFor({ state: 'visible' });
    await expect(input).toBeEnabled();

    const interactiveTime = Date.now() - startTime;

    // Should be interactive within 2 seconds
    expect(interactiveTime).toBeLessThan(2000);
  });

  test('should not have memory leaks during interactions', async ({ page }) => {
    await page.goto('/');

    // Get initial memory usage
    const initialMetrics = await page.evaluate(() => {
      if ((performance as any).memory) {
        return (performance as any).memory.usedJSHeapSize;
      }
      return null;
    });

    // Perform multiple interactions
    const input = page.locator('#HelloWorld-react-component-1 input');
    for (let i = 0; i < 100; i++) {
      await input.fill(`Test ${i}`);
    }

    // Force garbage collection if possible
    await page.evaluate(() => {
      if ((window as any).gc) {
        (window as any).gc();
      }
    });

    // Check memory after interactions
    const finalMetrics = await page.evaluate(() => {
      if ((performance as any).memory) {
        return (performance as any).memory.usedJSHeapSize;
      }
      return null;
    });

    if (initialMetrics && finalMetrics) {
      // Memory should not increase by more than 10MB
      const memoryIncrease = finalMetrics - initialMetrics;
      expect(memoryIncrease).toBeLessThan(10 * 1024 * 1024);
    }
  });

  test('should efficiently handle rapid state changes', async ({ page }) => {
    await page.goto('/');

    const input = page.locator('#ReduxApp-react-component-0 input');
    const heading = page.locator('#ReduxApp-react-component-0 h3');

    // Rapidly change input
    const testString = 'Performance test with rapid typing';
    await input.type(testString, { delay: 10 });

    // Verify the final state is correct
    await expect(heading).toContainText(testString);
  });
});
