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
    await page.evaluate(() => localStorage.removeItem('__rendererCleanupCount__'));

    // Trigger a Turbo navigation. The fixture records cleanup in localStorage so
    // the assertion survives Turbo-triggered reloads when tracked assets force a full refresh.
    await Promise.all([
      page.waitForURL('**/manual_render_test'),
      page.locator('#renderer-cleanup-leave-link').click(),
    ]);
    // Wait for content unique to the destination page rather than `networkidle`.
    await expect(page.locator('#ManualRenderComponent-1')).toBeVisible();

    // The framework called the teardown, root.unmount() ran, the tree's
    // useEffect cleanup fired, and the persisted counter is 1. localStorage
    // survives Turbo-triggered reloads when tracked assets force a full refresh.
    expect(await page.evaluate(() => localStorage.getItem('__rendererCleanupCount__'))).toBe('1');
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
      const reactOnRails = window.ReactOnRails;
      if (!reactOnRails) {
        throw new Error('ReactOnRails global not found; check client-bundle.js registration');
      }
      return reactOnRails.reactOnRailsPageLoaded();
    });

    // The prior teardown ran on same-id replacement, unmounting the old root
    // and firing useEffect cleanup → counter is 1. The newly mounted root for
    // the replaced node has not been unmounted yet, so the counter stays at 1.
    expect(await page.evaluate(() => window.__rendererCleanupCount__ || 0)).toBe(1);
  });
});
