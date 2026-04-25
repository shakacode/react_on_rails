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
 *   2. The TrackedTree inside the renderer flips `window.__rendererCleanupRan__ = true`
 *      from its useEffect cleanup — i.e. only when React actually unmounts the tree.
 *   3. Click a Turbo link and assert the flag is now true.
 *
 * The renderer (RendererCleanupTest.jsx) returns `() => root.unmount()` as its teardown.
 * Today this return value is silently ignored, so the assertion fails. Once Issue #3209
 * lands, the framework will call the teardown on `turbo:before-render`, root.unmount()
 * runs, useEffect cleanup runs, and the flag becomes true.
 */
test.describe('Issue #3209: Renderer function teardown on Turbo navigation', () => {
  test.beforeEach(async () => {
    await app('clean');
  });

  test('invokes the renderer-returned teardown when navigating away via Turbo', async ({
    page,
  }) => {
    await page.goto('/renderer_cleanup_test');
    await page.waitForLoadState('networkidle');

    // Sanity: the tree is mounted and the flag was reset to false at mount time.
    await expect(page.locator('[data-testid="renderer-cleanup-tree"]')).toBeVisible();
    const beforeNav = await page.evaluate(() => window.__rendererCleanupRan__);
    expect(beforeNav).toBe(false);

    // Trigger a Turbo navigation. Window globals persist across Turbo visits, so the
    // flag set during unmount on the previous page is visible on the new page.
    await Promise.all([
      page.waitForURL('**/manual_render_test'),
      page.click('#renderer-cleanup-leave-link'),
    ]);
    await page.waitForLoadState('networkidle');

    // After the fix: the framework called our teardown, root.unmount() ran,
    // TrackedTree's useEffect cleanup fired, the flag is true.
    const afterNav = await page.evaluate(() => window.__rendererCleanupRan__);
    expect(afterNav).toBe(true);
  });

  test('invokes the renderer-returned teardown when the same domNodeId is replaced', async ({
    page,
  }) => {
    await page.goto('/renderer_cleanup_test');
    await page.waitForLoadState('networkidle');

    await expect(page.locator('[data-testid="renderer-cleanup-tree"]')).toBeVisible();
    expect(await page.evaluate(() => window.__rendererCleanupRan__)).toBe(false);

    // Replace the mount node in place (e.g. mimicking async HTML injection) and
    // re-trigger the page-loaded sweep. The framework must invoke the prior renderer's
    // teardown before mounting on the new node, otherwise the previous root is leaked.
    await page.evaluate(() => {
      const old = document.getElementById('RendererCleanupTest-1');
      const replacement = document.createElement('div');
      replacement.id = 'RendererCleanupTest-1';
      old.replaceWith(replacement);
      // eslint-disable-next-line no-undef
      ReactOnRails.reactOnRailsPageLoaded();
    });

    // After the fix: the prior teardown ran during the same-id replacement path,
    // unmounting the old root and firing useEffect cleanup → flag is true.
    const cleanupRan = await page.evaluate(() => window.__rendererCleanupRan__);
    expect(cleanupRan).toBe(true);
  });
});
