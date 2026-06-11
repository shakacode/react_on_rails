/**
 * @jest-environment jsdom
 */

import type * as RootErrorHandlersModule from '../src/rootErrorHandlers.ts';

type RootErrorHandlersModuleType = typeof RootErrorHandlersModule;

// The module under test reads the React version through reactApis.cts at load time, so each test
// re-requires it after mocking react-dom with the version it needs (same pattern as
// reactHydrateOrRender.test.ts).
const loadModule = (reactDomVersion: string): RootErrorHandlersModuleType => {
  jest.resetModules();
  jest.doMock('react-dom', () => ({
    version: reactDomVersion,
    // Legacy APIs so reactApis.cts module-load validation passes for React 16/17 versions.
    hydrate: jest.fn(),
    render: jest.fn(),
    unmountComponentAtNode: jest.fn(),
  }));
  jest.doMock('react-dom/client', () => ({
    createRoot: jest.fn(),
    hydrateRoot: jest.fn(),
  }));
  // eslint-disable-next-line @typescript-eslint/no-require-imports, global-require
  return require('../src/rootErrorHandlers.ts') as RootErrorHandlersModuleType;
};

const setRailsContext = (railsEnv: string): void => {
  const el = document.createElement('div');
  el.id = 'js-react-on-rails-context';
  el.textContent = JSON.stringify({ railsEnv, serverSide: false });
  document.body.appendChild(el);
};

describe('rootErrorHandlers', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    document.body.innerHTML = '';
  });

  afterEach(() => {
    // getRailsContext caches per module registry; reset so the next loadModule starts clean.
    jest.resetModules();
  });

  describe('setRootErrorHandlers validation', () => {
    it('throws when a handler is not a function', () => {
      const { setRootErrorHandlers } = loadModule('19.0.0');
      expect(() => setRootErrorHandlers({ onRecoverableError: 'nope' as unknown as () => void })).toThrow(
        /onRecoverableError must be a function/,
      );
    });

    it('stores and resets handlers', () => {
      const { setRootErrorHandlers, getRootErrorHandlers, resetRootErrorHandlers } = loadModule('19.0.0');
      const onRecoverableError = jest.fn();
      setRootErrorHandlers({ onRecoverableError });
      expect(getRootErrorHandlers().onRecoverableError).toBe(onRecoverableError);
      resetRootErrorHandlers();
      expect(getRootErrorHandlers()).toEqual({});
    });
  });

  describe('legacy React (<18)', () => {
    it('warns at registration and builds no callback options', () => {
      const { setRootErrorHandlers, buildRootErrorCallbackOptions } = loadModule('17.0.2');
      setRootErrorHandlers({ onRecoverableError: jest.fn(), onUncaughtError: jest.fn() });
      expect(console.warn).toHaveBeenCalledWith(expect.stringContaining('require the React 18+ root APIs'));
      expect(buildRootErrorCallbackOptions({ componentName: 'X', domNodeId: 'x' }, true)).toEqual({});
    });

    it('does not warn when no handlers are registered', () => {
      const { setRootErrorHandlers } = loadModule('16.14.0');
      setRootErrorHandlers({});
      expect(console.warn).not.toHaveBeenCalled();
    });
  });

  describe('React 18', () => {
    it('supports onRecoverableError but warns about and drops React 19-only callbacks', () => {
      const { setRootErrorHandlers, buildRootErrorCallbackOptions } = loadModule('18.3.1');
      setRootErrorHandlers({
        onRecoverableError: jest.fn(),
        onCaughtError: jest.fn(),
        onUncaughtError: jest.fn(),
      });
      expect(console.warn).toHaveBeenCalledWith(
        expect.stringContaining('onCaughtError, onUncaughtError) require React 19'),
      );
      const options = buildRootErrorCallbackOptions({ componentName: 'X', domNodeId: 'x' }, true);
      expect(options.onRecoverableError).toEqual(expect.any(Function));
      expect(options.onCaughtError).toBeUndefined();
      expect(options.onUncaughtError).toBeUndefined();
    });

    it('does not warn when only onRecoverableError is registered', () => {
      const { setRootErrorHandlers } = loadModule('18.3.1');
      setRootErrorHandlers({ onRecoverableError: jest.fn() });
      expect(console.warn).not.toHaveBeenCalled();
    });
  });

  describe('React 19', () => {
    it('wraps all three handlers and invokes them with the enriched context', () => {
      const { setRootErrorHandlers, buildRootErrorCallbackOptions } = loadModule('19.0.0');
      const onRecoverableError = jest.fn();
      const onCaughtError = jest.fn();
      const onUncaughtError = jest.fn();
      setRootErrorHandlers({ onRecoverableError, onCaughtError, onUncaughtError });
      expect(console.warn).not.toHaveBeenCalled();

      const context = { componentName: 'MyComponent', domNodeId: 'my-dom-id' };
      const options = buildRootErrorCallbackOptions(context, true);
      const error = new Error('boom');
      const errorInfo = { componentStack: 'at MyComponent' };

      options.onRecoverableError?.(error, errorInfo);
      expect(onRecoverableError).toHaveBeenCalledWith(error, errorInfo, context);
      options.onCaughtError?.(error, errorInfo);
      expect(onCaughtError).toHaveBeenCalledWith(error, errorInfo, context);
      options.onUncaughtError?.(error, errorInfo);
      expect(onUncaughtError).toHaveBeenCalledWith(error, errorInfo, context);
    });

    it('returns empty options when nothing is registered and not in development', () => {
      const { buildRootErrorCallbackOptions } = loadModule('19.0.0');
      setRailsContext('test');
      expect(buildRootErrorCallbackOptions({ componentName: 'X', domNodeId: 'x' }, true)).toEqual({});
    });

    it('logs (and swallows) when an async user callback rejects', async () => {
      const { setRootErrorHandlers, buildRootErrorCallbackOptions } = loadModule('19.0.0');
      const rejection = new Error('async handler boom');
      setRootErrorHandlers({
        // An async handler is assignable to the void-returning handler type; its rejection must
        // be adopted and logged instead of escaping as an unhandled promise rejection.
        onRecoverableError: jest.fn(() => Promise.reject(rejection)),
      });
      const options = buildRootErrorCallbackOptions({ componentName: 'X', domNodeId: 'x' }, true);
      expect(() => options.onRecoverableError?.(new Error('boom'), undefined)).not.toThrow();

      // Flush microtasks so the swallowing .catch runs.
      await new Promise((resolve) => {
        setTimeout(resolve, 0);
      });
      expect(console.error).toHaveBeenCalledWith(
        expect.stringContaining('rootErrorHandlers.onRecoverableError callback threw'),
        rejection,
      );
    });

    it('logs (and does not rethrow) when a user callback throws', () => {
      const { setRootErrorHandlers, buildRootErrorCallbackOptions } = loadModule('19.0.0');
      const handlerError = new Error('handler boom');
      setRootErrorHandlers({
        onRecoverableError: jest.fn(() => {
          throw handlerError;
        }),
      });
      const options = buildRootErrorCallbackOptions({ componentName: 'X', domNodeId: 'x' }, true);
      expect(() => options.onRecoverableError?.(new Error('boom'), undefined)).not.toThrow();
      expect(console.error).toHaveBeenCalledWith(
        expect.stringContaining('rootErrorHandlers.onRecoverableError callback threw'),
        handlerError,
      );
    });
  });

  describe('development-mode default hydration-mismatch logger', () => {
    it('attaches on the hydrate path in development even without a user callback', () => {
      const module = loadModule('19.0.0');
      setRailsContext('development');
      const options = module.buildRootErrorCallbackOptions(
        { componentName: 'DevComponent', domNodeId: 'dev-dom-id' },
        true,
      );
      expect(options.onRecoverableError).toEqual(expect.any(Function));

      const error = new Error('Hydration failed');
      options.onRecoverableError?.(error, undefined);
      expect(console.error).toHaveBeenCalledWith(
        expect.stringContaining(
          'Recoverable hydration error in component "DevComponent" (dom id: "dev-dom-id")',
        ),
        error,
      );
      expect(console.error).toHaveBeenCalledWith(
        expect.stringContaining(module.HYDRATION_MISMATCH_GUIDE_URL),
        error,
      );
    });

    it('runs alongside (before) a registered user onRecoverableError', () => {
      const module = loadModule('19.0.0');
      setRailsContext('development');
      const callOrder: string[] = [];
      (console.error as jest.Mock).mockImplementation(() => callOrder.push('devLog'));
      module.setRootErrorHandlers({
        onRecoverableError: jest.fn(() => callOrder.push('user')),
      });

      const options = module.buildRootErrorCallbackOptions({ componentName: 'X', domNodeId: 'x' }, true);
      options.onRecoverableError?.(new Error('boom'), undefined);
      expect(callOrder).toEqual(['devLog', 'user']);
    });

    it('does not attach on the non-hydrate (createRoot) path', () => {
      const module = loadModule('19.0.0');
      setRailsContext('development');
      const options = module.buildRootErrorCallbackOptions({ componentName: 'X', domNodeId: 'x' }, false);
      expect(options.onRecoverableError).toBeUndefined();
    });

    it('does not attach outside development', () => {
      const module = loadModule('19.0.0');
      setRailsContext('production');
      const options = module.buildRootErrorCallbackOptions({ componentName: 'X', domNodeId: 'x' }, true);
      expect(options.onRecoverableError).toBeUndefined();
    });
  });
});
