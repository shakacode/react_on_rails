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

// Number of concurrent page loads per test (limited to avoid overwhelming server)
const CONCURRENT_LOADS = 6;

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
  async function loadPageAndCheckErrors(
    page: Page,
    delay: number,
    loadId: string,
    pageTimeout: number = 15000,
    propsSize: number = 1,
  ): Promise<LoadResult> {
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

    const url = `/large_props_stress_test?delay=${delay}&load_id=${loadId}&size=${propsSize}`;

    try {
      await page.goto(url, { waitUntil: 'domcontentloaded', timeout: pageTimeout * 2 });

      // Wait for components to render (with timeout)
      await page.waitForSelector('[data-testid="test-status"]', { timeout: pageTimeout });

      // Wait for status to be set
      await page.waitForFunction(
        () => {
          const el = document.getElementById('test-status');
          return el && el.dataset.status;
        },
        { timeout: pageTimeout },
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

  test('should handle concurrent page loads with network throttling (slow 3G)', async ({ browser }) => {
    test.setTimeout(180000); // 3 minutes - slow network takes longer
    const results = await runConcurrentLoads(browser, 100, CONCURRENT_LOADS, 'slow3g');
    // Allow timeouts on slow network, but fail on JSON parse errors
    analyzeResults(results, 100, true);
  });

  test('EXTREME: very slow network (GPRS) with 1MB+ props', async ({ browser }) => {
    test.setTimeout(600000); // 10 minutes for extreme test
    // Use size=5 for ~1MB props per component, GPRS-like network
    const results = await runConcurrentLoads(browser, 100, 3, 'gprs', 5);
    analyzeResults(results, 100, true);
  });

  test('stress test: many iterations with varying delays', async ({ browser }) => {
    test.setTimeout(300000); // 5 minutes for this stress test
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
   * @param throttle - false, 'slow3g', or 'gprs'
   * @param propsSize - size multiplier for props (1 = ~200KB, 5 = ~1MB)
   */
  async function runConcurrentLoads(
    browser: Browser,
    delay: number,
    count: number,
    throttle: false | 'slow3g' | 'gprs' = false,
    propsSize: number = 1,
  ): Promise<LoadResult[]> {
    const promises: Promise<LoadResult>[] = [];

    for (let i = 0; i < count; i++) {
      const context: BrowserContext = await browser.newContext();
      const page: Page = await context.newPage();

      // Simulate slow network to trigger race condition
      if (throttle) {
        const cdp = await context.newCDPSession(page);
        const networkConditions =
          throttle === 'gprs'
            ? {
                offline: false,
                downloadThroughput: (50 * 1024) / 8, // 50 Kbps - GPRS
                uploadThroughput: (20 * 1024) / 8,
                latency: 500, // 500ms latency
              }
            : {
                offline: false,
                downloadThroughput: (500 * 1024) / 8, // 500 Kbps - slow 3G
                uploadThroughput: (500 * 1024) / 8,
                latency: 400, // 400ms latency
              };
        await cdp.send('Network.emulateNetworkConditions', networkConditions);
      }

      const loadId = `load-${delay}ms-${i}${throttle ? `-${throttle}` : ''}${propsSize > 1 ? `-${propsSize}x` : ''}`;
      const pageTimeout = throttle === 'gprs' ? 300000 : throttle ? 60000 : 15000;

      promises.push(
        loadPageAndCheckErrors(page, delay, loadId, pageTimeout, propsSize).finally(async () => {
          try {
            await context.close();
          } catch {
            // Context may already be closed on timeout
          }
        }),
      );
    }

    return Promise.all(promises);
  }

  /**
   * Analyze and log results
   */
  function analyzeResults(results: LoadResult[], delay: number, allowTimeouts: boolean = false): void {
    const failures = results.filter((r) => !r.success);
    const jsonErrors = results.filter((r) => r.jsonErrors.length > 0);
    const timeouts = failures.filter((r) => r.errors.some((e) => e.includes('timeout') || e.includes('Timeout')));

    console.log(`\n--- Results for delay=${delay}ms ---`);
    console.log(
      `Total: ${results.length}, Success: ${results.length - failures.length}, Failed: ${failures.length}, Timeouts: ${timeouts.length}`,
    );

    if (failures.length > 0) {
      console.log('Failure details:');
      failures.forEach((r) => console.log(`  ${r.loadId}: ${r.errors.join(', ')}`));
    }

    if (jsonErrors.length > 0) {
      console.error('!!! JSON PARSE ERRORS DETECTED !!!');
      jsonErrors.forEach((r) => console.error(`  ${r.loadId}:`, r.jsonErrors));
    }

    // JSON parse errors are the bug we're looking for - always fail on these
    expect(jsonErrors.length).toBe(0);

    // For throttled tests, we allow timeouts but not other failures
    if (!allowTimeouts) {
      expect(failures.length).toBe(0);
    }
  }
});

/**
 * Additional test: Rapid sequential loads
 * This tests a different pattern - rapid back-to-back loads
 */
test.describe('Rapid Sequential Load Test', () => {
  test.describe.configure({ timeout: 120000 });

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
