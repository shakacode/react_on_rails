import { test, expect } from '@playwright/test';
import { app } from '../../support/on-rails';

/**
 * Issue #3892: React 19 root error callbacks registered globally via
 * `ReactOnRails.setOptions({ rootErrorHandlers })` (see client-bundle.ts) must fire for
 * components rendered by React on Rails. The dummy handlers record each invocation on
 * `window.__ROOT_ERROR_CALLBACK_EVENTS__` with the enriched context (componentName, domNodeId).
 */
test.describe('React root error callbacks (rootErrorHandlers)', () => {
  test.beforeEach(async () => {
    await app('clean');
  });

  const getEvents = (page, kind) =>
    page.evaluate(
      // eslint-disable-next-line no-underscore-dangle
      (wantedKind) => (window.__ROOT_ERROR_CALLBACK_EVENTS__ || []).filter((e) => e.kind === wantedKind),
      kind,
    );

  test('onRecoverableError fires with component context for a server-rendered+hydrated component with a forced mismatch', async ({
    page,
  }) => {
    await page.goto('/root_error_callbacks');

    // The component recovers by client re-rendering, so it stays visible.
    const component = page.locator('#HydrationMismatchComponent-react-component-0');
    await expect(component).toBeVisible();
    await expect(component.getByTestId('mismatch-content')).toContainText('Render token:');

    // Hydration (and the recoverable-error callback) happens asynchronously after load.
    await expect.poll(async () => (await getEvents(page, 'recoverable')).length).toBeGreaterThan(0);

    const [event] = await getEvents(page, 'recoverable');
    expect(event.componentName).toBe('HydrationMismatchComponent');
    expect(event.domNodeId).toBe('HydrationMismatchComponent-react-component-0');
  });

  test('onUncaughtError fires with component context for a client-rendered component that throws during render', async ({
    page,
  }) => {
    await page.goto('/root_error_callbacks');
    test.skip(
      // eslint-disable-next-line no-underscore-dangle
      !(await page.evaluate(() => window.__ROOT_ERROR_CALLBACK_SUPPORTS_REACT19__)),
      'React 19 root error callbacks are not available in this matrix',
    );

    const thrower = page.locator('#RootErrorThrower-react-component-0');
    await expect(thrower.getByRole('button', { name: 'Throw render error' })).toBeVisible();

    // No uncaught events before the deliberate throw.
    expect(await getEvents(page, 'uncaught')).toHaveLength(0);

    await thrower.getByRole('button', { name: 'Throw render error' }).click();

    await expect.poll(async () => (await getEvents(page, 'uncaught')).length).toBeGreaterThan(0);

    const [event] = await getEvents(page, 'uncaught');
    expect(event.componentName).toBe('RootErrorThrower');
    expect(event.domNodeId).toBe('RootErrorThrower-react-component-0');
    expect(event.message).toContain('Deliberate uncaught render error');
  });

  test('onCaughtError fires with component context when an error boundary catches the render error', async ({
    page,
  }) => {
    await page.goto('/root_error_callbacks');
    test.skip(
      // eslint-disable-next-line no-underscore-dangle
      !(await page.evaluate(() => window.__ROOT_ERROR_CALLBACK_SUPPORTS_REACT19__)),
      'React 19 root error callbacks are not available in this matrix',
    );

    const thrower = page.locator('#RootErrorBoundaryThrower-react-component-0');
    await expect(thrower.getByRole('button', { name: 'Throw boundary error' })).toBeVisible();

    expect(await getEvents(page, 'caught')).toHaveLength(0);

    await thrower.getByRole('button', { name: 'Throw boundary error' }).click();

    await expect.poll(async () => (await getEvents(page, 'caught')).length).toBeGreaterThan(0);
    await expect(thrower.getByRole('status')).toHaveText('Boundary caught render error');

    const [event] = await getEvents(page, 'caught');
    expect(event.componentName).toBe('RootErrorBoundaryThrower');
    expect(event.domNodeId).toBe('RootErrorBoundaryThrower-react-component-0');
    expect(event.message).toContain('Deliberate caught render error');
  });
});
