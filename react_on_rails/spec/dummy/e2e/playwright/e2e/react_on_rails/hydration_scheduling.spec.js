import { test, expect } from '@playwright/test';
import { app } from '../../support/on-rails';

const hydrationEvents = (page) =>
  page.evaluate(() => {
    // eslint-disable-next-line no-underscore-dangle
    return window.__HYDRATION_SCHEDULING_EVENTS__ || [];
  });

test.describe('hydrate_on scheduling', () => {
  test.beforeEach(async () => {
    await app('clean');
  });

  test('hydrates immediate mode on page load', async ({ page }) => {
    await page.goto('/hydration_scheduling');

    const immediate = page.getByTestId('hydrate-immediate');
    await expect(immediate).toHaveAttribute('data-hydrated', 'true');
    await expect(immediate.getByRole('button')).toBeEnabled();

    await expect
      .poll(async () => hydrationEvents(page))
      .toContainEqual(
        expect.objectContaining({ event: 'hydrated', mode: 'immediate', testId: 'hydrate-immediate' }),
      );
  });

  test('hydrates idle mode during an idle callback or timeout fallback', async ({ page }) => {
    await page.addInitScript(() => {
      // eslint-disable-next-line no-underscore-dangle
      window.__HYDRATE_ON_IDLE_CALLBACKS__ = [];
      window.requestIdleCallback = (callback) => {
        // eslint-disable-next-line no-underscore-dangle
        window.__HYDRATE_ON_IDLE_CALLBACKS__.push(callback);
        // eslint-disable-next-line no-underscore-dangle
        return window.__HYDRATE_ON_IDLE_CALLBACKS__.length;
      };
      window.cancelIdleCallback = () => {};
    });

    await page.goto('/hydration_scheduling');

    const idle = page.getByTestId('hydrate-idle');
    await expect(idle).toHaveAttribute('data-hydrated', 'false');
    await page.evaluate(() => {
      // eslint-disable-next-line no-underscore-dangle
      window.__HYDRATE_ON_IDLE_CALLBACKS__.forEach((callback) => callback());
    });
    await expect(idle).toHaveAttribute('data-hydrated', 'true');
    await expect(idle.getByRole('button')).toBeEnabled();
  });

  test('hydrates visible mode only after the island scrolls into view', async ({ page }) => {
    await page.goto('/hydration_scheduling');

    const visible = page.getByTestId('hydrate-visible');
    await expect(visible).toHaveAttribute('data-hydrated', 'false');

    await visible.scrollIntoViewIfNeeded();

    await expect(visible).toHaveAttribute('data-hydrated', 'true');
    await expect(visible.getByRole('button')).toBeEnabled();
  });

  test('disconnects pending visible observers on Turbo navigation', async ({ page }) => {
    await page.addInitScript(() => {
      function TestIntersectionObserver() {
        // eslint-disable-next-line no-underscore-dangle
        window.__HYDRATE_ON_INTERSECTION_OBSERVERS__ ||= [];
        // eslint-disable-next-line no-underscore-dangle
        window.__HYDRATE_ON_INTERSECTION_OBSERVERS__.push(this);
        this.observe = () => {};
        this.disconnect = () => {
          // eslint-disable-next-line no-underscore-dangle
          window.__HYDRATE_ON_DISCONNECTS__ = (window.__HYDRATE_ON_DISCONNECTS__ || 0) + 1;
        };
      }

      // eslint-disable-next-line no-underscore-dangle
      window.__HYDRATE_ON_DISCONNECTS__ = 0;
      window.IntersectionObserver = TestIntersectionObserver;
    });

    await page.goto('/hydration_scheduling');
    await expect
      .poll(() =>
        page.evaluate(() => {
          // eslint-disable-next-line no-underscore-dangle
          return (window.__HYDRATE_ON_INTERSECTION_OBSERVERS__ || []).length;
        }),
      )
      .toBeGreaterThan(0);

    await page.evaluate(() => {
      document.dispatchEvent(new Event('turbo:before-render'));
    });

    await expect
      .poll(() =>
        page.evaluate(() => {
          // eslint-disable-next-line no-underscore-dangle
          return window.__HYDRATE_ON_DISCONNECTS__ || 0;
        }),
      )
      .toBeGreaterThan(0);
  });
});
