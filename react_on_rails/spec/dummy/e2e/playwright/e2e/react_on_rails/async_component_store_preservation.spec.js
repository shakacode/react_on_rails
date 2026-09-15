import { test, expect } from '@playwright/test';
import { app } from '../../support/on-rails';

/**
 * Tests for Issue #4862: renderComponent / reactOnRailsComponentLoaded re-runs every store
 * generator, discarding hydrated Redux state.
 *
 * `ReactOnRails.reactOnRailsComponentLoaded(domId)` is the documented core API for rendering a
 * component whose HTML was injected after page load (fetched fragments, lazy panels, infinite
 * scroll). Before the fix, it re-ran EVERY store generator on the page from the original
 * server-sent props, replacing already-hydrated stores in the registry:
 *
 *   - state accumulated since page load was discarded, and
 *   - components mounted earlier kept the old store instance while the new island (and any
 *     later `getStore()` call) got the new one — two disagreeing stores under one name, with
 *     dispatches in one island never reaching the other.
 *
 * The page under test renders one Redux-connected island at page load, then fetches a
 * server-rendered fragment containing a second island bound to the same `SharedReduxStore`
 * and activates it with `reactOnRailsComponentLoaded()`. The store's `name` field (edited
 * through the first island's input) is the accumulated-state probe.
 */
test.describe('Issue #4862: reactOnRailsComponentLoaded() store preservation', () => {
  const UPDATED_NAME = 'Accumulated After Page Load';

  const firstIslandInput = (page) => page.locator('#ReduxSharedStoreApp-react-component-0 input');
  const secondIslandInput = (page) => page.locator('#ReduxSharedStoreApp-react-component-1 input');

  const loadPageAndAccumulateState = async (page) => {
    await page.goto('/async_component_shared_store');

    // The first island is interactive and shows the server-sent name from the store
    // ('Mr. Server Side Rendering' comes from @app_props_server_render in the dummy
    // PagesController). Confirming it rendered also makes the later "shows the updated
    // value" assertions meaningful — the server value was present, then superseded.
    await expect(firstIslandInput(page)).toHaveValue('Mr. Server Side Rendering');

    // Accumulate client-side state in the shared store, as a user would after page load.
    await firstIslandInput(page).fill(UPDATED_NAME);
    await expect(firstIslandInput(page)).toHaveValue(UPDATED_NAME);
  };

  const loadAsyncIsland = async (page) => {
    await page.click('#load-async-island-btn');
    await expect(secondIslandInput(page)).toBeVisible();
  };

  test.beforeEach(async () => {
    await app('clean');
  });

  test('async island renders with the accumulated store state, not the original server props', async ({
    page,
  }) => {
    await loadPageAndAccumulateState(page);
    await loadAsyncIsland(page);

    // Before the fix: the async island mounted against a freshly re-created store and showed
    // the original server-sent name, while the first island still showed the accumulated one.
    await expect(secondIslandInput(page)).toHaveValue(UPDATED_NAME);
    await expect(firstIslandInput(page)).toHaveValue(UPDATED_NAME);
  });

  test('both islands stay connected to the same store after the async render', async ({ page }) => {
    await loadPageAndAccumulateState(page);
    await loadAsyncIsland(page);

    // Dispatch from the async island; the first island must observe the update.
    await secondIslandInput(page).fill('Edited In Async Island');
    await expect(firstIslandInput(page)).toHaveValue('Edited In Async Island');

    // And the reverse direction: dispatch from the first island, async island observes it.
    await firstIslandInput(page).fill('Edited In First Island');
    await expect(secondIslandInput(page)).toHaveValue('Edited In First Island');
  });

  test('declared-deps async island takes the dependency-scoped path and stays connected', async ({
    page,
  }) => {
    const declaredIslandInput = (p) => p.locator('#ReduxSharedStoreApp-react-component-2 input');

    await loadPageAndAccumulateState(page);

    await page.click('#load-declared-async-island-btn');
    await expect(declaredIslandInput(page)).toBeVisible();

    // The fragment's react_component call declares store_dependencies, so the injected spec tag
    // carries the exact attribute Rails emits and core's dependency-scoped initialization reads.
    // This pins the Ruby-emission ↔ JS-parsing seam the jest fixtures can only fake.
    const declaredDeps = await page.getAttribute(
      '[data-dom-id="ReduxSharedStoreApp-react-component-2"]',
      'data-store-dependencies',
    );
    expect(JSON.parse(declaredDeps)).toEqual(['SharedReduxStore']);

    // The fragment also carries a store element with no registered generator. The island being
    // visible above proves the scoped path ignored it — the legacy sweep threw on it before
    // rendering the island. Pin the element is really present so this net cannot rot silently.
    const unregisteredStoreCount = await page
      .locator('[data-js-react-on-rails-store="UnregisteredTestStore"]')
      .count();
    expect(unregisteredStoreCount).toBe(1);

    // Scoped initialization skips the already-hydrated store: accumulated state survives...
    await expect(declaredIslandInput(page)).toHaveValue(UPDATED_NAME);

    // ...and the island is live-connected to the same store instance as the first island.
    await declaredIslandInput(page).fill('Edited In Declared Island');
    await expect(firstIslandInput(page)).toHaveValue('Edited In Declared Island');
  });

  test('getStore() returns the same store instance after the async render', async ({ page }) => {
    await loadPageAndAccumulateState(page);

    await page.evaluate(() => {
      // eslint-disable-next-line no-underscore-dangle -- double-underscore marks the test-only window global
      window.__STORE_BEFORE_ASYNC_RENDER__ = window.ReactOnRails.getStore('SharedReduxStore');
    });

    await loadAsyncIsland(page);

    const sameInstance = await page.evaluate(
      // eslint-disable-next-line no-underscore-dangle -- double-underscore marks the test-only window global
      () => window.ReactOnRails.getStore('SharedReduxStore') === window.__STORE_BEFORE_ASYNC_RENDER__,
    );
    expect(sameInstance).toBe(true);
  });
});
