import { test, expect, type Page } from '@playwright/test';

const STRESS_URL = '/server_router/refetch-stress';
const visibleByTestId = (page: Page, testId: string) => page.getByTestId(testId).filter({ visible: true });

test.describe('Imperative RSC refetch — stress scenarios (Issue 3106)', () => {
  test.beforeEach(async ({ page }) => {
    // Relative URL — Playwright prepends `use.baseURL` from playwright.config.ts
    // (`http://localhost:3000/`). For local runs against a non-standard port,
    // change baseURL in playwright.config.ts (it does not currently honor a
    // BASE_URL env var override).
    await page.goto(STRESS_URL);
    await expect(visibleByTestId(page, 'stress-time-ref-handle')).toBeVisible();
  });

  test('1. ref handle: button click visibly refreshes the timestamp', async ({ page }) => {
    const before = await visibleByTestId(page, 'stress-time-ref-handle').textContent();
    await visibleByTestId(page, 'ref-refetch-button').click();
    await expect
      .poll(() => visibleByTestId(page, 'stress-time-ref-handle').textContent(), { timeout: 5000 })
      .not.toBe(before);
  });

  test('2. inside-RSC hook: button click visibly refreshes the timestamp', async ({ page }) => {
    const before = await visibleByTestId(page, 'stress-time-inside-hook').textContent();
    await visibleByTestId(page, 'stress-inline-inside-hook').click();
    await expect
      .poll(() => visibleByTestId(page, 'stress-time-inside-hook').textContent(), { timeout: 5000 })
      .not.toBe(before);
  });

  test('3. multi-instance fan-out: two cards with same key both update on one refetch', async ({ page }) => {
    // Two separate <span data-testid="stress-time-shared"> in DOM — they share
    // the cache key, so both must update together.
    const initial = await visibleByTestId(page, 'stress-time-shared').allTextContents();
    expect(initial).toHaveLength(2);
    expect(initial[0]).toBe(initial[1]); // initial render: same payload
    await visibleByTestId(page, 'multi-refetch-button').click();
    await expect
      .poll(
        async () => {
          const ts = await visibleByTestId(page, 'stress-time-shared').allTextContents();
          return ts.length === 2 && ts[0] === ts[1] && ts[0] !== initial[0];
        },
        { timeout: 5000 },
      )
      .toBe(true);
  });

  test('4. independent siblings: refreshing left does not change right', async ({ page }) => {
    const leftBefore = await visibleByTestId(page, 'stress-time-indep-left').textContent();
    const rightBefore = await visibleByTestId(page, 'stress-time-indep-right').textContent();
    await visibleByTestId(page, 'indep-left-button').click();
    await expect
      .poll(() => visibleByTestId(page, 'stress-time-indep-left').textContent(), { timeout: 5000 })
      .not.toBe(leftBefore);
    expect(await visibleByTestId(page, 'stress-time-indep-right').textContent()).toBe(rightBefore);
  });

  test('5. captured handle: refetch after props change uses the LATEST props', async ({ page }) => {
    // step 1: capture refetch when label = captured-v1
    await visibleByTestId(page, 'captured-grab').click();
    // step 2: change props (label becomes captured-v2)
    await visibleByTestId(page, 'captured-bump').click();
    // wait for the card to mount under the new key
    await expect(visibleByTestId(page, 'stress-card-captured-v2')).toBeVisible();
    const before = await visibleByTestId(page, 'stress-time-captured-v2').textContent();
    // step 3: invoke the captured handle. It should refetch v2's payload.
    await visibleByTestId(page, 'captured-invoke').click();
    await expect
      .poll(() => visibleByTestId(page, 'stress-time-captured-v2').textContent(), { timeout: 5000 })
      .not.toBe(before);
  });

  test('6. rapid double-click: UI ends up showing the latest payload', async ({ page }) => {
    const before = await visibleByTestId(page, 'stress-time-rapid').textContent();
    const rapidButton = visibleByTestId(page, 'rapid-button');
    await rapidButton.click();
    await rapidButton.click();
    await expect
      .poll(() => visibleByTestId(page, 'stress-time-rapid').textContent(), { timeout: 5000 })
      .not.toBe(before);
  });

  test('7. many siblings: refresh-all updates each card independently', async ({ page }) => {
    const before = await Promise.all(
      [0, 1, 2, 3, 4].map((i) => visibleByTestId(page, `stress-time-many-${i}`).textContent()),
    );
    await visibleByTestId(page, 'many-refresh-all').click();
    await expect
      .poll(
        async () => {
          const after = await Promise.all(
            [0, 1, 2, 3, 4].map((i) => visibleByTestId(page, `stress-time-many-${i}`).textContent()),
          );
          return after.every((v, i) => v && v !== before[i]);
        },
        { timeout: 10000 },
      )
      .toBe(true);
  });

  test('8. mount/unmount: ref.current is null after unmount, set after re-mount', async ({ page }) => {
    // The page renders 'unchecked' until the button is pressed, so the
    // first assertion is a real ref read, not a seeded display value.
    await expect(visibleByTestId(page, 'mount-ref-state')).toHaveText('ref.current: unchecked');

    // While mounted, the ref is set.
    await visibleByTestId(page, 'mount-check-ref').click();
    await expect(visibleByTestId(page, 'mount-ref-state')).toHaveText('ref.current: set');

    // unmount
    await visibleByTestId(page, 'mount-toggle').click();
    await visibleByTestId(page, 'mount-check-ref').click();
    await expect(visibleByTestId(page, 'mount-ref-state')).toHaveText('ref.current: null');

    // re-mount
    await visibleByTestId(page, 'mount-toggle').click();
    await expect(visibleByTestId(page, 'stress-card-mount-cycle')).toBeVisible();
    await visibleByTestId(page, 'mount-check-ref').click();
    await expect(visibleByTestId(page, 'mount-ref-state')).toHaveText('ref.current: set');
  });
});
