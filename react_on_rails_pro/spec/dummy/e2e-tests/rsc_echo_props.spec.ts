/**
 * RSC Echo Props — Issue #2435 Reproduction Tests
 *
 * Tests that RSC components correctly receive props containing special characters
 * that trigger the .replace() $-pattern corruption bug during SERVER-SIDE rendering.
 *
 * Issue: https://github.com/shakacode/react_on_rails/issues/2435
 *
 * Root cause: String.prototype.replace() interprets $-patterns in replacement strings:
 *   $`  → inserts portion of string BEFORE the match
 *   $'  → inserts portion of string AFTER the match
 *   $&  → inserts the matched substring
 *
 * When props contain "$`" (common in markdown with bash variables), the .replace() call
 * in generateRSCPayload corrupts the rendering request, producing garbled JS code.
 *
 * IMPORTANT: When SSR fails, the client falls back to fetching the RSC payload via
 * a separate HTTP request to /rsc_payload/:component_name, which bypasses the buggy
 * code path and renders correctly. To ensure we're testing SSR (where the bug lives),
 * we intercept and abort all /rsc_payload/ requests so the client-side fallback cannot
 * mask the bug.
 *
 * Tests 1-3 should pass even without the fix.
 * Tests 4-6 will FAIL until the fix is applied (components will error or hang).
 */

import { test, expect } from '@playwright/test';

const COMPONENT_RENDER_TIMEOUT = 15000;

/**
 * Blocks all client-side RSC payload fetch requests.
 * This prevents the client-side fallback from masking SSR failures.
 */
async function blockRscPayloadRequests(page: import('@playwright/test').Page) {
  await page.route('**/rsc_payload/**', (route) => route.abort());
}

/**
 * Navigates to the RSC echo props page and waits for initial HTML.
 * Uses waitUntil: 'commit' because the page uses streaming.
 */
async function navigateToEchoPropsPage(page: import('@playwright/test').Page) {
  await page.goto('/rsc_echo_props', { waitUntil: 'commit' });
}

/**
 * Waits for a specific RSC echo props component to render and returns its parsed props.
 */
async function getRenderedProps(page: import('@playwright/test').Page, containerId: string) {
  const pre = page.locator(`#${containerId} pre`);
  await expect(pre).toBeVisible({ timeout: COMPONENT_RENDER_TIMEOUT });
  const text = await pre.textContent();
  return JSON.parse(text!);
}

test.describe('RSC Echo Props — Issue #2435', () => {
  test.beforeEach(async ({ page }) => {
    await blockRscPayloadRequests(page);
  });

  test('Test 1: safe props render correctly (baseline)', async ({ page }) => {
    await navigateToEchoPropsPage(page);
    const props = await getRenderedProps(page, 'rsc-echo-safe');

    expect(props.test).toBe('safe_props');
    expect(props.name).toBe('World');
    expect(props.count).toBe(42);
  });

  test('Test 2: props with backticks (markdown code) render correctly', async ({ page }) => {
    await navigateToEchoPropsPage(page);
    const props = await getRenderedProps(page, 'rsc-echo-backticks');

    expect(props.test).toBe('backticks');
    expect(props.content).toBe('Check this: `const x = 1`');
  });

  test('Test 3: props with ${} template syntax render correctly', async ({ page }) => {
    await navigateToEchoPropsPage(page);
    const props = await getRenderedProps(page, 'rsc-echo-template');

    expect(props.test).toBe('template_syntax');
    expect(props.content).toBe('Value is ${process.env.SECRET}');
  });

  test('Test 4: props with $` (dollar-backtick) render correctly — THE BUG', async ({ page }) => {
    await navigateToEchoPropsPage(page);
    const props = await getRenderedProps(page, 'rsc-echo-dollar-backtick');

    expect(props.test).toBe('dollar_backtick');
    expect(props.content).toBe('Price is $`100');
  });

  test('Test 5: props with bash variable in inline code render correctly', async ({ page }) => {
    await navigateToEchoPropsPage(page);
    const props = await getRenderedProps(page, 'rsc-echo-bash');

    expect(props.test).toBe('bash_variable');
    expect(props.content).toBe('Run `echo $`HOME to see your home directory');
  });

  test('Test 6: props with backticks + ${} combined render correctly', async ({ page }) => {
    await navigateToEchoPropsPage(page);
    const props = await getRenderedProps(page, 'rsc-echo-combined');

    expect(props.test).toBe('combined');
    expect(props.content).toBe('Check this code: `const x = ${y}`');
  });
});
