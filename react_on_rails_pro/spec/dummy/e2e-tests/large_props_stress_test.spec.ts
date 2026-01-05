/**
 * Large Props Stress Test
 *
 * This test attempts to reproduce the non-deterministic JSON parsing error
 * reported in https://github.com/shakacode/react_on_rails/issues/2283
 *
 * The error: "SyntaxError: Unterminated string in JSON at position 171120"
 *
 * Conditions:
 * - Large props (~200KB JSON)
 * - Immediate hydration enabled (Pro default)
 * - Async component registration (simulated via delay)
 * - Multiple concurrent page loads
 */

import { test, expect, Browser, Page, ConsoleMessage, type BrowserContext } from '@playwright/test';

// Number of concurrent page loads per test
const CONCURRENT_LOADS = 10;

// Number of iterations (total loads = CONCURRENT_LOADS * ITERATIONS)
const ITERATIONS = 5;

// Different registration delays to test (in ms)
const REGISTRATION_DELAYS = [0, 50, 100, 200, 500];

interface LoadResult {
  loadId: string;
  delay: number;
  status: string | null;
  errors: string[];
  jsonErrors: Array<{
    error: string;
    textLength: number;
    firstChars: string;
    lastChars: string;
    timestamp: string;
  }>;
  consoleMessages: Array<{ type: string; text: string }>;
  success: boolean;
}

test.describe('Large Props JSON Parsing Stress Test', () => {
  test.describe.configure({ mode: 'parallel' });

  /**
   * Helper to load a page and check for JSON parse errors
   */
  async function loadPageAndCheckErrors(page: Page, delay: number, loadId: string): Promise<LoadResult> {
    const errors: string[] = [];
    const consoleMessages: Array<{ type: string; text: string }> = [];

    // Capture all console messages
    page.on('console', (msg: ConsoleMessage) => {
      const text = msg.text();
      consoleMessages.push({ type: msg.type(), text });

      if (msg.type() === 'error') {
        errors.push(text);
      }
    });

    // Capture page errors (uncaught exceptions)
    page.on('pageerror', (error: Error) => {
      errors.push(`PageError: ${error.message}`);
    });

    const url = `/large_props_stress_test?delay=${delay}&load_id=${loadId}`;

    try {
      await page.goto(url, { waitUntil: 'domcontentloaded' });

      // Wait for components to render (with timeout)
      await page.waitForSelector('[data-testid="test-status"]', { timeout: 15000 });

      // Wait for status to be set
      await page.waitForFunction(
        () => {
          const el = document.getElementById('test-status');
          return el && el.dataset.status;
        },
        { timeout: 15000 },
      );

      // Get the status
      const statusElement = page.locator('#test-status');
      const status = await statusElement.getAttribute('data-status');

      // Check for JSON parse errors captured by our monkey-patch
      const jsonErrors = await page.evaluate(
        () =>
          (window as unknown as { __JSON_PARSE_ERRORS__?: LoadResult['jsonErrors'] }).__JSON_PARSE_ERRORS__ ||
          [],
      );

      return {
        loadId,
        delay,
        status,
        errors,
        jsonErrors,
        consoleMessages: consoleMessages.filter((m) => m.type === 'error'),
        success: status === 'success' && errors.length === 0 && jsonErrors.length === 0,
      };
    } catch (e) {
      return {
        loadId,
        delay,
        status: 'exception',
        errors: [...errors, (e as Error).message],
        jsonErrors: [],
        consoleMessages: [],
        success: false,
      };
    }
  }

  test('should handle single page load with large props', async ({ page }) => {
    const result = await loadPageAndCheckErrors(page, 100, 'single');

    console.log('Single load result:', {
      status: result.status,
      errors: result.errors,
      jsonErrors: result.jsonErrors,
    });

    expect(result.success).toBe(true);
    expect(result.jsonErrors).toHaveLength(0);
  });

  test('should handle concurrent page loads with immediate registration (delay=0)', async ({ browser }) => {
    const results = await runConcurrentLoads(browser, 0, CONCURRENT_LOADS);
    analyzeResults(results, 0);
  });

  test('should handle concurrent page loads with 100ms delay', async ({ browser }) => {
    const results = await runConcurrentLoads(browser, 100, CONCURRENT_LOADS);
    analyzeResults(results, 100);
  });

  test('should handle concurrent page loads with 200ms delay', async ({ browser }) => {
    const results = await runConcurrentLoads(browser, 200, CONCURRENT_LOADS);
    analyzeResults(results, 200);
  });

  test('stress test: many iterations with varying delays', async ({ browser }) => {
    const allResults: LoadResult[] = [];

    for (let iteration = 0; iteration < ITERATIONS; iteration++) {
      for (const delay of REGISTRATION_DELAYS) {
        const results = await runConcurrentLoads(browser, delay, CONCURRENT_LOADS);
        allResults.push(...results);
      }
    }

    // Analyze all results
    const totalLoads = allResults.length;
    const failures = allResults.filter((r) => !r.success);
    const jsonParseErrors = allResults.filter((r) => r.jsonErrors.length > 0);

    console.log('\n========== STRESS TEST SUMMARY ==========');
    console.log(`Total page loads: ${totalLoads}`);
    console.log(`Successful: ${totalLoads - failures.length}`);
    console.log(`Failed: ${failures.length}`);
    console.log(`JSON parse errors: ${jsonParseErrors.length}`);

    if (failures.length > 0) {
      console.log('\n--- Failure Details ---');
      failures.forEach((f) => {
        console.log(`Load ${f.loadId} (delay=${f.delay}ms): ${f.errors.join(', ')}`);
        if (f.jsonErrors.length > 0) {
          console.log('  JSON errors:', JSON.stringify(f.jsonErrors, null, 2));
        }
      });
    }

    // The test passes if error rate is below 1% (allowing for some flakiness)
    // But we want to detect ANY JSON parse errors as those are the bug we're looking for
    if (jsonParseErrors.length > 0) {
      console.error('\n!!! JSON PARSE ERRORS DETECTED - BUG REPRODUCED !!!');
      jsonParseErrors.forEach((r) => {
        console.error(`Load ${r.loadId}:`, r.jsonErrors);
      });
    }

    // Fail if we see JSON parse errors (the bug we're trying to reproduce)
    expect(jsonParseErrors).toHaveLength(0);
  });

  /**
   * Run concurrent page loads
   */
  async function runConcurrentLoads(browser: Browser, delay: number, count: number): Promise<LoadResult[]> {
    const promises: Promise<LoadResult>[] = [];

    for (let i = 0; i < count; i++) {
      const context: BrowserContext = await browser.newContext();
      const page: Page = await context.newPage();
      const loadId = `load-${delay}ms-${i}`;

      promises.push(
        loadPageAndCheckErrors(page, delay, loadId).finally(async () => {
          await context.close();
        }),
      );
    }

    return Promise.all(promises);
  }

  /**
   * Analyze and log results
   */
  function analyzeResults(results: LoadResult[], delay: number): void {
    const failures = results.filter((r) => !r.success);
    const jsonErrors = results.filter((r) => r.jsonErrors.length > 0);

    console.log(`\n--- Results for delay=${delay}ms ---`);
    console.log(
      `Total: ${results.length}, Success: ${results.length - failures.length}, Failed: ${failures.length}`,
    );

    if (jsonErrors.length > 0) {
      console.error('JSON parse errors detected:');
      jsonErrors.forEach((r) => console.error(`  ${r.loadId}:`, r.jsonErrors));
    }

    // We expect all loads to succeed
    expect(failures.length).toBe(0);
    expect(jsonErrors.length).toBe(0);
  }
});

/**
 * Additional test: Rapid sequential loads
 * This tests a different pattern - rapid back-to-back loads
 */
test.describe('Rapid Sequential Load Test', () => {
  test('should handle rapid sequential page loads', async ({ page }) => {
    const results: Array<{
      loadIndex: number;
      success: boolean;
      errors: string[];
      jsonErrors: LoadResult['jsonErrors'];
    }> = [];
    const RAPID_LOADS = 20;

    for (let i = 0; i < RAPID_LOADS; i++) {
      const errors: string[] = [];

      page.on('console', (msg: ConsoleMessage) => {
        if (msg.type() === 'error' && !msg.text().includes('immediate_hydration')) {
          errors.push(msg.text());
        }
      });

      await page.goto(`/large_props_stress_test?delay=50&rapid_load=${i}`, {
        waitUntil: 'domcontentloaded',
      });

      try {
        await page.waitForSelector('[data-testid="status"]', { timeout: 10000 });
        const jsonErrors = await page.evaluate(
          () =>
            (window as unknown as { __JSON_PARSE_ERRORS__?: LoadResult['jsonErrors'] })
              .__JSON_PARSE_ERRORS__ || [],
        );

        results.push({
          loadIndex: i,
          success: errors.length === 0 && jsonErrors.length === 0,
          errors,
          jsonErrors,
        });
      } catch (e) {
        results.push({
          loadIndex: i,
          success: false,
          errors: [...errors, (e as Error).message],
          jsonErrors: [],
        });
      }
    }

    const failures = results.filter((r) => !r.success);
    const jsonParseErrors = results.filter((r) => r.jsonErrors.length > 0);

    console.log(`Rapid sequential loads: ${RAPID_LOADS}, Failures: ${failures.length}`);

    if (jsonParseErrors.length > 0) {
      console.error('JSON parse errors in rapid sequential test:', jsonParseErrors);
    }

    expect(jsonParseErrors).toHaveLength(0);
  });
});
