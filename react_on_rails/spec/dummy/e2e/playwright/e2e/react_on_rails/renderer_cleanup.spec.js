/* eslint-disable no-underscore-dangle */
import { test, expect } from '@playwright/test';
import { app } from '../../support/on-rails';

/**
 * Tests for Issue #3209: Renderer functions are never cleaned up on Turbo navigation.
 *
 * A renderer function (3-arg `(props, railsContext, domNodeId) => …`) registered with
 * ReactOnRails takes responsibility for mounting its own React root. Today the framework
 * discards anything the renderer returns, so when Turbo navigates away there is no
 * `root.unmount()` call — the React tree is leaked and its useEffect cleanups never run.
 *
 * This spec drives the fix end-to-end:
 *   1. Visit a page that mounts a renderer-function-driven component.
 *   2. The TrackedTree inside the renderer increments
 *      `window.__rendererCleanupCount__` from its useEffect cleanup — i.e. only
 *      when React actually unmounts the tree.
 *   3. Trigger an unmount path (Turbo navigation, or same-id node replacement) and
 *      assert the counter increased.
 *
 * The renderer (RendererCleanupTest.jsx) returns `() => root.unmount()` as its teardown.
 * Today this return value is silently ignored, so the counter stays at 0 and the
 * assertions fail. Once Issue #3209 lands, the framework will call the teardown,
 * root.unmount() runs, useEffect cleanup runs, and the counter increments to 1.
 */
test.describe('Issue #3209: Renderer function teardown on Turbo navigation', () => {
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

    // After the fix: the framework called our teardown, root.unmount() ran,
    // TrackedTree's useEffect cleanup fired, the counter is 1.
    expect(await page.evaluate(() => window.__rendererCleanupCount__)).toBe(1);
  });

  test('invokes the renderer-returned teardown when the same domNodeId is replaced', async ({ page }) => {
    await page.goto('/renderer_cleanup_test');

    await expect(page.locator('[data-testid="renderer-cleanup-tree"]')).toBeVisible();
    expect(await page.evaluate(() => window.__rendererCleanupCount__ || 0)).toBe(0);

    // Replace the mount node in place (e.g. mimicking async HTML injection) and
    // re-trigger the page-loaded sweep. The framework must invoke the prior renderer's
    // teardown before mounting on the new node, otherwise the previous root is leaked.
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

    // After the fix: the prior teardown ran during the same-id replacement path,
    // unmounting the old root and firing useEffect cleanup → counter is 1.
    // (The newly mounted root for the replaced node has not been unmounted yet,
    // so the counter stays at 1, not 2.)
    expect(await page.evaluate(() => window.__rendererCleanupCount__)).toBe(1);
  });
});
