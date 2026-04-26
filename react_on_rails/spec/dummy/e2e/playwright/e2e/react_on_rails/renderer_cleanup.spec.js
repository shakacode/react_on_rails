/* eslint-disable no-underscore-dangle */
import { test, expect } from '@playwright/test';
import { app } from '../../support/on-rails';

/**
 * E2E coverage for renderer-function teardowns.
 *
 * A renderer function (3-arg `(props, railsContext, domNodeId) => …`) registered
 * with ReactOnRails takes responsibility for mounting its own React root. When
 * it returns a teardown closure, the framework invokes that closure on Turbo
 * navigation and on same-id node replacement — unmounting the root and firing
 * any useEffect cleanups on the tree.
 *
 * These tests assert the contract end-to-end through the dummy app:
 *   1. Visit a page that mounts a renderer-function-driven component.
 *   2. The TrackedTree inside the renderer increments
 *      `window.__rendererCleanupCount__` from its useEffect cleanup, which
 *      runs only when the framework unmounts the root.
 *   3. Trigger an unmount path (Turbo navigation, or same-id node replacement)
 *      and assert the counter went up.
 */
test.describe('Renderer function teardown', () => {
  test.beforeEach(async () => {
    await app('clean');
  });

  test('invokes the renderer-returned teardown when navigating away via Turbo', async ({ page }) => {
    await page.goto('/renderer_cleanup_test');

    // Sanity: the tree is mounted and no cleanup has run yet. `toBeVisible`
    // auto-waits, so we don't need a `networkidle` gate (which can flake on
    // pages with background pollers/analytics).
    await expect(page.locator('[data-testid="renderer-cleanup-tree"]')).toBeVisible();
    expect(await page.evaluate(() => window.__rendererCleanupCount__ || 0)).toBe(0);

    // Trigger a Turbo navigation. Window globals persist across Turbo visits, so the
    // counter incremented during unmount on the previous page is visible on the new page.
    await Promise.all([page.waitForURL('**/manual_render_test'), page.click('#renderer-cleanup-leave-link')]);
    // Wait for content unique to the destination page rather than `networkidle`.
    await expect(page.locator('#ManualRenderComponent-1')).toBeVisible();

    // The framework called the teardown, root.unmount() ran, the tree's
    // useEffect cleanup fired, and the counter is 1. `|| 0` so a missing
    // counter reads `Received: 0` instead of `Received: undefined` in failures.
    expect(await page.evaluate(() => window.__rendererCleanupCount__ || 0)).toBe(1);
  });

  test('invokes the renderer-returned teardown when the same domNodeId is replaced', async ({ page }) => {
    await page.goto('/renderer_cleanup_test');

    await expect(page.locator('[data-testid="renderer-cleanup-tree"]')).toBeVisible();
    expect(await page.evaluate(() => window.__rendererCleanupCount__ || 0)).toBe(0);

    // Replace the mount node in place (e.g. mimicking async HTML injection) and
    // re-trigger the page-loaded sweep. The framework invokes the prior renderer's
    // teardown before mounting on the new node so the previous root isn't leaked.
    await page.evaluate(() => {
      const old = document.getElementById('RendererCleanupTest-1');
      const replacement = document.createElement('div');
      replacement.id = 'RendererCleanupTest-1';
      old.replaceWith(replacement);
      // Returning the promise so Playwright awaits it — protects this assertion
      // if reactOnRailsPageLoaded ever becomes truly async at the call site.
      // eslint-disable-next-line no-undef
      return ReactOnRails.reactOnRailsPageLoaded();
    });

    // The prior teardown ran on same-id replacement, unmounting the old root
    // and firing useEffect cleanup → counter is 1. The newly mounted root for
    // the replaced node has not been unmounted yet, so the counter stays at 1.
    expect(await page.evaluate(() => window.__rendererCleanupCount__ || 0)).toBe(1);
  });
});
