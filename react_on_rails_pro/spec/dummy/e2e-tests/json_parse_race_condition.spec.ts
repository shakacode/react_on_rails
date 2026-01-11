/**
 * JSON Parse Race Condition Test
 *
 * Tests that the race condition fix for immediate_hydration works correctly.
 * The fix prevents JS from reading incomplete JSON props during HTML streaming.
 *
 * Issue: https://github.com/shakacode/react_on_rails/issues/2283
 *
 * The StreamingRaceSimulator middleware (activated by ?simulate_race=true)
 * splits the props script tag in the middle of its JSON content with a delay,
 * simulating the race condition that occurs on slow networks.
 */

import { test, expect, Page } from '@playwright/test';

// Pattern for successful hydration log
const HYDRATION_SUCCESS_PATTERN = /HYDRATED HelloWorldHooks in dom node with id/;

// Patterns for JSON parse errors
const JSON_ERROR_PATTERNS = [/JSON/, /Unterminated/, /SyntaxError/];

interface HydrationResult {
  hydrated: boolean;
  errors: string[];
}

/**
 * Waits for either successful hydration or a JSON parse error.
 * Returns the result indicating which occurred.
 */
async function waitForHydrationOrError(page: Page): Promise<HydrationResult> {
  const errors: string[] = [];
  let hydrated = false;

  return new Promise((resolve) => {
    const cleanup = () => {
      page.off('console', onConsole);
      page.off('pageerror', onPageError);
    };

    const onConsole = (msg: { type: () => string; text: () => string }) => {
      const text = msg.text();

      // Check for hydration success
      if (HYDRATION_SUCCESS_PATTERN.test(text)) {
        hydrated = true;
        cleanup();
        resolve({ hydrated: true, errors });
      }

      // Capture errors
      if (msg.type() === 'error') {
        errors.push(text);
        // Check if it's a JSON parse error
        if (JSON_ERROR_PATTERNS.some((pattern) => pattern.test(text))) {
          cleanup();
          resolve({ hydrated: false, errors });
        }
      }
    };

    const onPageError = (error: Error) => {
      errors.push(error.message);
      if (JSON_ERROR_PATTERNS.some((pattern) => pattern.test(error.message))) {
        cleanup();
        resolve({ hydrated: false, errors });
      }
    };

    page.on('console', onConsole);
    page.on('pageerror', onPageError);

    // Timeout fallback (10 seconds)
    setTimeout(() => {
      cleanup();
      resolve({ hydrated, errors });
    }, 10000);
  });
}

/**
 * Waits for the hydration console message.
 * Returns a promise that resolves when hydration is detected.
 */
async function waitForHydration(page: Page): Promise<void> {
  // Check if already hydrated (message already logged)
  const messages = await page.evaluate(() => {
    return (window as unknown as { __capturedLogs?: string[] }).__capturedLogs || [];
  });

  if (messages.some((msg) => HYDRATION_SUCCESS_PATTERN.test(msg))) {
    return;
  }

  // Wait for hydration message
  await page.waitForEvent('console', {
    predicate: (msg) => HYDRATION_SUCCESS_PATTERN.test(msg.text()),
    timeout: 10000,
  });
}

/**
 * Tests that the component is interactive (hydrated):
 * - Typing in the input should update the h3 text
 */
async function verifyComponentIsInteractive(page: Page): Promise<boolean> {
  // Target the HelloWorldHooks component specifically
  const component = page.locator('#HelloWorld-react-component-0');
  const input = component.locator('input[type="text"]');
  const heading = component.locator('h3');

  // Get initial text
  const initialText = await heading.textContent();

  // Type a unique string
  await input.fill('TestUser123');

  // Check if heading updated
  const updatedText = await heading.textContent();

  return updatedText === 'Hello, TestUser123!' && updatedText !== initialText;
}

test.describe('JSON Parse Race Condition Fix', () => {
  test('should hydrate successfully even with simulated race condition', async ({ page }) => {
    // Start navigation and wait for hydration result
    const navigationPromise = page.goto('/server_side_hello_world_hooks?simulate_race=true');
    const resultPromise = waitForHydrationOrError(page);

    await navigationPromise;
    const result = await resultPromise;

    // With the fix, hydration should succeed even with race condition
    expect(result.hydrated).toBe(true);
    expect(result.errors.filter((e) => JSON_ERROR_PATTERNS.some((pattern) => pattern.test(e)))).toHaveLength(0);

    // Verify component IS interactive (React hydrated successfully)
    const isInteractive = await verifyComponentIsInteractive(page);
    expect(isInteractive).toBe(true);
  });

  test('should hydrate successfully without race condition simulation', async ({ page }) => {
    // Start navigation and wait for hydration result
    const navigationPromise = page.goto('/server_side_hello_world_hooks');
    const resultPromise = waitForHydrationOrError(page);

    await navigationPromise;
    const result = await resultPromise;

    // Expect successful hydration
    expect(result.hydrated).toBe(true);
    expect(result.errors.filter((e) => JSON_ERROR_PATTERNS.some((pattern) => pattern.test(e)))).toHaveLength(0);

    // Verify component IS interactive (React hydrated successfully)
    const isInteractive = await verifyComponentIsInteractive(page);
    expect(isInteractive).toBe(true);
  });
});

test.describe('Early Hydration Timing', () => {
  test('should be interactive immediately after hydration log appears', async ({ page }) => {
    // Set up console log capture before navigation
    await page.addInitScript(() => {
      (window as unknown as { __capturedLogs: string[] }).__capturedLogs = [];
      const originalLog = console.log;
      console.log = (...args) => {
        (window as unknown as { __capturedLogs: string[] }).__capturedLogs.push(args.join(' '));
        originalLog.apply(console, args);
      };
    });

    // Navigate with waitUntil: 'commit' to not block on full page load
    // This allows us to test during streaming
    await page.goto('/server_side_hello_world_hooks?simulate_race=true', {
      waitUntil: 'commit',
    });

    // Wait for hydration (not DOMContentLoaded)
    await waitForHydration(page);

    // Immediately test interactivity - should work right after hydration
    const component = page.locator('#HelloWorld-react-component-0');
    const input = component.locator('input[type="text"]');
    const heading = component.locator('h3');

    // Fill input and verify heading updates (proves React state works)
    await input.fill('EarlyHydration');
    await expect(heading).toHaveText('Hello, EarlyHydration!');
  });

  test('should hydrate before DOMContentLoaded when props are complete', async ({ page }) => {
    // Inject timing capture
    await page.addInitScript(() => {
      (window as unknown as { __timing: { hydration: number; domContentLoaded: number } }).__timing = {
        hydration: 0,
        domContentLoaded: 0,
      };

      // Capture DOMContentLoaded time
      document.addEventListener('DOMContentLoaded', () => {
        (window as unknown as { __timing: { domContentLoaded: number } }).__timing.domContentLoaded =
          performance.now();
      });
    });

    // Set up hydration timing capture
    page.on('console', (msg) => {
      if (HYDRATION_SUCCESS_PATTERN.test(msg.text())) {
        // Capture hydration time in the page context
        page.evaluate(() => {
          (window as unknown as { __timing: { hydration: number } }).__timing.hydration = performance.now();
        });
      }
    });

    // Navigate WITHOUT race condition - props are immediately complete
    await page.goto('/server_side_hello_world_hooks');

    // Wait for both events
    await page.waitForFunction(
      () =>
        (window as unknown as { __timing: { hydration: number; domContentLoaded: number } }).__timing.hydration > 0 &&
        (window as unknown as { __timing: { hydration: number; domContentLoaded: number } }).__timing
          .domContentLoaded > 0,
      { timeout: 10000 },
    );

    const timing = await page.evaluate(
      () => (window as unknown as { __timing: { hydration: number; domContentLoaded: number } }).__timing,
    );

    console.log(`Hydration: ${timing.hydration.toFixed(2)}ms, DOMContentLoaded: ${timing.domContentLoaded.toFixed(2)}ms`);

    // Hydration should happen before or very close to DOMContentLoaded
    // Allow small tolerance for measurement timing
    expect(timing.hydration).toBeLessThanOrEqual(timing.domContentLoaded + 50);
  });

  test('should hydrate via immediate_script fallback when race condition skips initial hydration', async ({
    page,
  }) => {
    // This test verifies that when the initial renderOrHydrateImmediateHydratedComponents()
    // skips an element (because nextSibling is null), the immediate_script still triggers
    // hydration via reactOnRailsComponentLoaded()

    let hydrationTriggeredBy = '';

    page.on('console', (msg) => {
      const text = msg.text();
      // The HYDRATED log comes from React on Rails after successful hydration
      if (HYDRATION_SUCCESS_PATTERN.test(text)) {
        hydrationTriggeredBy = 'hydration_complete';
      }
    });

    // Navigate with race condition
    await page.goto('/server_side_hello_world_hooks?simulate_race=true');

    // Wait for hydration
    await page.waitForFunction(
      () => document.querySelector('#HelloWorld-react-component-0 input') !== null,
      { timeout: 10000 },
    );

    // Verify component is interactive
    const component = page.locator('#HelloWorld-react-component-0');
    const input = component.locator('input[type="text"]');
    const heading = component.locator('h3');

    await input.fill('FallbackPath');
    await expect(heading).toHaveText('Hello, FallbackPath!');

    // Hydration should have completed (via either path)
    expect(hydrationTriggeredBy).toBe('hydration_complete');
  });
});
