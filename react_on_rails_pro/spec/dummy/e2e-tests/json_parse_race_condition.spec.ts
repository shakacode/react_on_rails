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
