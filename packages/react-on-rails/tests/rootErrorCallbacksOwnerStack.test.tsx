/**
 * @jest-environment jsdom
 */

/**
 * Positive-path coverage for issue #3887's client owner-stack enrichment.
 *
 * The workspace React is 19.0.x, where `captureOwnerStack` does not exist, so the real-runtime
 * integration test in `rootErrorCallbacks.test.tsx` can only exercise the no-op branch. Here we mock
 * `captureReactOwnerStack` to model a React >= 19.1 dev build (owner stacks available) and assert the
 * branded dev-mode render-error line actually carries the owner chain. This is the CI-runnable
 * substitute for the dev-only browser behavior (the dummy e2e cannot run because the Playwright
 * harness boots Rails in `test`, while the owner-stack logger is gated to `development`).
 */

const OWNER_STACK = '\n    at OwnerStackInner\n    at OwnerStackMiddle\n    at OwnerStackThrower';

jest.mock('../src/captureReactOwnerStack.ts', () => ({
  __esModule: true,
  default: jest.fn(() => OWNER_STACK),
  isOwnerStackSupported: jest.fn(() => true),
}));

import {
  buildRootErrorCallbackOptions,
  setRootErrorHandlers,
  resetRootErrorHandlers,
} from '../src/rootErrorHandlers.ts';
import { resetRailsContext } from '../src/context.ts';
import { supportsReact19RootErrorCallbacks } from '../src/reactApis.cts';

const setupRailsContext = (railsEnv: string): void => {
  const el = document.createElement('div');
  el.id = 'js-react-on-rails-context';
  el.textContent = JSON.stringify({
    railsEnv,
    inMailer: false,
    i18nLocale: 'en',
    i18nDefaultLocale: 'en',
    rorVersion: '17.0.0',
    rorPro: false,
    href: 'http://localhost:3000',
    location: 'http://localhost:3000',
    scheme: 'http',
    host: 'localhost',
    port: 3000,
    pathname: '/',
    search: null,
    httpAcceptLanguage: 'en',
    serverSide: false,
    componentRegistryTimeout: 0,
  });
  document.body.appendChild(el);
};

const react19Describe = supportsReact19RootErrorCallbacks ? describe : describe.skip;

react19Describe('client owner-stack enrichment with owner stacks available (issue #3887)', () => {
  let consoleErrorSpy: jest.SpyInstance;

  beforeEach(() => {
    resetRootErrorHandlers();
    resetRailsContext();
    document.body.innerHTML = '';
    consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => undefined);
  });

  afterEach(() => {
    consoleErrorSpy.mockRestore();
    resetRootErrorHandlers();
    resetRailsContext();
  });

  const brandedRenderErrorLine = (): string | undefined =>
    consoleErrorSpy.mock.calls
      .map((call) => call[0])
      .find(
        (arg): arg is string =>
          typeof arg === 'string' && arg.includes('[ReactOnRails] Render error in component'),
      );

  it('appends the owner chain to a dev app-registered onUncaughtError handler and still forwards to it', () => {
    setupRailsContext('development');
    const appOnUncaughtError = jest.fn();
    setRootErrorHandlers({ onUncaughtError: appOnUncaughtError });
    const context = { componentName: 'OwnerStackThrower', domNodeId: 'owner-dom-id' };

    const options = buildRootErrorCallbackOptions(context, false);
    expect(options.onUncaughtError).toBeDefined();

    // errorInfo has no `ownerStack` field (React < 19.2 shape) so the logger falls back to the
    // mocked live `captureReactOwnerStack()`.
    const error = new Error('deliberate render error');
    options.onUncaughtError?.(error, {});

    const line = brandedRenderErrorLine();
    expect(line).toBeDefined();
    expect(line).toContain('"OwnerStackThrower"');
    expect(line).toContain('Owner stack (the components that rendered this one):');
    expect(line).toContain('at OwnerStackMiddle');
    // The enrichment is purely additive: the app's own handler still runs, receiving React on Rails'
    // enriched context (component name + dom id) as the third argument.
    expect(appOnUncaughtError).toHaveBeenCalledWith(error, {}, context);
  });

  it('appends the owner chain to a dev app-registered onCaughtError handler with the error-boundary note', () => {
    setupRailsContext('development');
    const appOnCaughtError = jest.fn();
    setRootErrorHandlers({ onCaughtError: appOnCaughtError });
    const context = { componentName: 'OwnerStackThrower', domNodeId: 'owner-dom-id' };

    const options = buildRootErrorCallbackOptions(context, false);
    expect(options.onCaughtError).toBeDefined();

    const error = new Error('deliberate caught error');
    options.onCaughtError?.(error, {});

    const line = brandedRenderErrorLine();
    expect(line).toBeDefined();
    expect(line).toContain('"OwnerStackThrower"');
    expect(line).toContain('(caught by an error boundary)');
    expect(line).toContain('Owner stack (the components that rendered this one):');
    expect(line).toContain('at OwnerStackMiddle');
    expect(appOnCaughtError).toHaveBeenCalledWith(error, {}, context);
  });

  it('does not auto-attach a wrapper when the app registered no handler, leaving React defaults intact', () => {
    setupRailsContext('development');
    const context = { componentName: 'OwnerStackThrower', domNodeId: 'owner-dom-id' };

    // Even with owner stacks available and in development, we never displace React's built-in
    // caught/uncaught dev diagnostics when the app supplied no handler of its own.
    const options = buildRootErrorCallbackOptions(context, false);
    expect(options.onUncaughtError).toBeUndefined();
    expect(options.onCaughtError).toBeUndefined();
  });
});
