/**
 * @jest-environment jsdom
 */

import * as React from 'react';
import { renderComponent, reactOnRailsComponentLoaded } from '../src/ClientRenderer.ts';
import type { RendererFunction } from '../src/types/index.ts';
import ComponentRegistry from '../src/ComponentRegistry.ts';
import StoreRegistry from '../src/StoreRegistry.ts';

type PageUnloadCallback = () => void | Promise<void>;
type ErrorWithCause = Error & { cause?: unknown };

type GlobalWithPageUnloadCallbacks = typeof globalThis & {
  __REACT_ON_RAILS_TEST_PAGE_UNLOADED_CALLBACKS__?: PageUnloadCallback[];
};

jest.mock('../src/pageLifecycle.ts', () => ({
  onPageUnloaded: jest.fn((callback: PageUnloadCallback) => {
    const globalWithCallbacks = globalThis as GlobalWithPageUnloadCallbacks;
    globalWithCallbacks.__REACT_ON_RAILS_TEST_PAGE_UNLOADED_CALLBACKS__ ||= [];
    globalWithCallbacks.__REACT_ON_RAILS_TEST_PAGE_UNLOADED_CALLBACKS__.push(callback);
  }),
}));

// Mock React DOM methods since we're testing client-side rendering
jest.mock('../src/reactHydrateOrRender.ts', () => ({
  __esModule: true,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  default: jest.fn((domNode: Element, _reactElement: React.ReactElement) => {
    // eslint-disable-next-line no-param-reassign
    domNode.innerHTML = '<div>Rendered: test</div>';
  }),
}));

const runPageUnload = (): void => {
  const globalWithCallbacks = globalThis as GlobalWithPageUnloadCallbacks;
  globalWithCallbacks.__REACT_ON_RAILS_TEST_PAGE_UNLOADED_CALLBACKS__?.forEach((callback) => {
    void callback();
  });
};

const setupRailsContext = (): void => {
  const railsContextElement = document.createElement('div');
  railsContextElement.id = 'js-react-on-rails-context';
  railsContextElement.textContent = JSON.stringify({
    railsEnv: 'test',
    inMailer: false,
    i18nLocale: 'en',
    i18nDefaultLocale: 'en',
    rorVersion: '13.0.0',
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
  document.body.appendChild(railsContextElement);
};

describe('ClientRenderer', () => {
  beforeEach(() => {
    // Clear registries
    ComponentRegistry.clear();
    StoreRegistry.clearHydratedStores();

    // Clear DOM
    document.body.innerHTML = '';
    document.head.innerHTML = '';

    // Reset any global state
    // eslint-disable-next-line no-underscore-dangle, @typescript-eslint/no-explicit-any, @typescript-eslint/no-unsafe-member-access
    delete (globalThis as any).__REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__;
  });

  afterEach(() => {
    runPageUnload();
    ComponentRegistry.clear();
    StoreRegistry.clearHydratedStores();
  });

  describe('renderComponent', () => {
    it('renders a simple React component', () => {
      setupRailsContext();

      // Register a simple component
      const TestComponent: React.FC<{ message: string }> = ({ message }) =>
        React.createElement('div', null, `Hello, ${message}!`);

      ComponentRegistry.register({ TestComponent });

      // Setup DOM element with component data
      const componentElement = document.createElement('div');
      componentElement.className = 'js-react-on-rails-component';
      componentElement.setAttribute('data-component-name', 'TestComponent');
      componentElement.setAttribute('data-dom-id', 'test-component');
      componentElement.textContent = JSON.stringify({ message: 'World' });
      document.body.appendChild(componentElement);

      // Create target DOM node
      const targetNode = document.createElement('div');
      targetNode.id = 'test-component';
      document.body.appendChild(targetNode);

      // Test the rendering
      renderComponent('test-component');

      // Verify the component was rendered
      expect(targetNode.innerHTML).toContain('Rendered:');
    });

    it('handles missing Rails context gracefully', () => {
      // Don't setup Rails context - should return early without error
      renderComponent('test-component');
      // Test passes if no exception is thrown
      expect(true).toBe(true);
    });

    it('handles missing DOM element gracefully', () => {
      setupRailsContext();

      // Test with non-existent DOM ID
      expect(() => renderComponent('non-existent-component')).not.toThrow();
    });

    it('wraps immediate Error throws while preserving the original stack for diagnostics', () => {
      setupRailsContext();

      const TestComponent: React.FC<{ message: string }> = ({ message }) =>
        React.createElement('div', null, `Hello, ${message}!`);
      ComponentRegistry.register({ TestComponent });

      const componentElement = document.createElement('div');
      componentElement.className = 'js-react-on-rails-component';
      componentElement.setAttribute('data-component-name', 'TestComponent');
      componentElement.setAttribute('data-dom-id', 'immediate-error-stack');
      componentElement.textContent = JSON.stringify({ message: 'World' });
      document.body.appendChild(componentElement);

      const targetNode = document.createElement('div');
      targetNode.id = 'immediate-error-stack';
      document.body.appendChild(targetNode);

      const originalError = new Error('immediate original boom');
      originalError.stack =
        'Error: immediate original boom\n    at Component.render (/tmp/component.js:10:5)';
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
      const mockHydrateOrRender = require('../src/reactHydrateOrRender.ts').default as jest.Mock;
      mockHydrateOrRender.mockImplementationOnce(() => {
        throw originalError;
      });

      let thrownError: unknown;
      try {
        renderComponent('immediate-error-stack');
      } catch (error) {
        thrownError = error;
      }

      expect(thrownError).toBeInstanceOf(Error);
      expect((thrownError as Error).message).toBe(
        'ReactOnRails encountered an error while rendering component: TestComponent. See above error message.',
      );
      expect((thrownError as Error).stack).toBe(originalError.stack);
      expect((thrownError as ErrorWithCause).cause).toBe(originalError);
      expect(originalError.message).toBe('immediate original boom');
      expect(consoleErrorSpy).toHaveBeenCalledWith(originalError);

      consoleErrorSpy.mockRestore();
    });

    it('wraps immediate render errors without mutating or assuming the thrown value is an Error', () => {
      setupRailsContext();

      const TestComponent: React.FC<{ message: string }> = ({ message }) =>
        React.createElement('div', null, `Hello, ${message}!`);
      ComponentRegistry.register({ TestComponent });

      const componentElement = document.createElement('div');
      componentElement.className = 'js-react-on-rails-component';
      componentElement.setAttribute('data-component-name', 'TestComponent');
      componentElement.setAttribute('data-dom-id', 'immediate-render-error');
      componentElement.textContent = JSON.stringify({ message: 'World' });
      document.body.appendChild(componentElement);

      const targetNode = document.createElement('div');
      targetNode.id = 'immediate-render-error';
      document.body.appendChild(targetNode);

      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
      const mockHydrateOrRender = require('../src/reactHydrateOrRender.ts').default as jest.Mock;
      mockHydrateOrRender.mockImplementationOnce(() => {
        throw 'immediate string boom';
      });

      let thrownError: unknown;
      try {
        renderComponent('immediate-render-error');
      } catch (error) {
        thrownError = error;
      }

      expect(thrownError).toBeInstanceOf(Error);
      expect((thrownError as Error).message).toBe(
        'ReactOnRails encountered an error while rendering component: TestComponent. See above error message.',
      );
      expect(consoleErrorSpy).toHaveBeenCalledTimes(1);
      const loggedError = consoleErrorSpy.mock.calls[0][0] as ErrorWithCause;
      expect(loggedError).toBeInstanceOf(Error);
      expect(loggedError.message).toBe('immediate string boom');
      expect(loggedError.cause).toBe('immediate string boom');
      expect((thrownError as ErrorWithCause).cause).toBe(loggedError);

      consoleErrorSpy.mockRestore();
    });
  });

  // Issue #3209: renderer functions (the 3-arg `(props, railsContext, domNodeId)` form) own their
  // own mount. They may return a teardown wrapper so React on Rails can clean the mount up on
  // page unload (Turbo/Turbolinks navigation) or when the same dom-id node is replaced.
  describe('renderer functions (issue #3209: teardown cleanup)', () => {
    const setupRendererDom = (domId: string, componentName = 'TestRenderer'): HTMLElement => {
      const componentElement = document.createElement('div');
      componentElement.className = 'js-react-on-rails-component';
      componentElement.setAttribute('data-component-name', componentName);
      componentElement.setAttribute('data-dom-id', domId);
      componentElement.textContent = JSON.stringify({ test: 'data' });
      document.body.appendChild(componentElement);

      const targetNode = document.createElement('div');
      targetNode.id = domId;
      document.body.appendChild(targetNode);
      return targetNode;
    };

    beforeEach(() => {
      // Clear roots tracked by earlier tests so teardown assertions below are isolated.
      runPageUnload();
      setupRailsContext();
    });

    it('invokes the renderer with props, railsContext, and domNodeId', () => {
      const renderer = jest.fn();
      // A 3-argument function is classified as a renderer by ComponentRegistry. The `RendererFunction`
      // annotation strips the parameter optionality at compile time only, so the arrow keeps its
      // runtime arity of 3.
      const TestRenderer: RendererFunction = (props, railsContext, domNodeId) => {
        renderer(props, railsContext, domNodeId);
      };
      ComponentRegistry.register({ TestRenderer });
      setupRendererDom('renderer-invoke');

      renderComponent('renderer-invoke');

      expect(renderer).toHaveBeenCalledTimes(1);
      expect(renderer).toHaveBeenCalledWith(
        { test: 'data' },
        expect.objectContaining({ railsEnv: 'test' }),
        'renderer-invoke',
      );
    });

    it('runs the returned teardown wrapper on page unload', () => {
      const teardown = jest.fn();
      const renderer = jest.fn();
      const TestRenderer: RendererFunction = (props, railsContext, domNodeId) => {
        renderer(props, railsContext, domNodeId);
        return { teardown };
      };
      ComponentRegistry.register({ TestRenderer });
      setupRendererDom('renderer-unload');

      renderComponent('renderer-unload');
      expect(renderer).toHaveBeenCalledTimes(1);
      expect(teardown).not.toHaveBeenCalled();

      // Simulate Turbo/Turbolinks page unload.
      runPageUnload();
      expect(teardown).toHaveBeenCalledTimes(1);
    });

    it('runs the previous teardown when the same dom id node is replaced', () => {
      const teardown = jest.fn();
      const renderer = jest.fn();
      const TestRenderer: RendererFunction = (props, railsContext, domNodeId) => {
        renderer(props, railsContext, domNodeId);
        return { teardown };
      };
      ComponentRegistry.register({ TestRenderer });
      const targetNode1 = setupRendererDom('renderer-replace');

      renderComponent('renderer-replace');
      expect(renderer).toHaveBeenCalledTimes(1);
      expect(teardown).not.toHaveBeenCalled();

      // Replace the dom node (e.g. async HTML injection) and re-render the same id.
      targetNode1.remove();
      const targetNode2 = document.createElement('div');
      targetNode2.id = 'renderer-replace';
      document.body.appendChild(targetNode2);

      renderComponent('renderer-replace');

      // The previous mount's teardown ran, and the renderer mounted into the new node.
      expect(teardown).toHaveBeenCalledTimes(1);
      expect(renderer).toHaveBeenCalledTimes(2);
    });

    it('does not throw on unmount when the renderer returns nothing', () => {
      // Intentionally returns nothing (legacy renderer that does not opt into cleanup). Three
      // parameters keep its runtime arity at 3 so it is still classified as a renderer.
      const renderer = jest.fn();
      const TestRenderer: RendererFunction = (_props, _railsContext, _domNodeId) => {
        renderer();
      };
      ComponentRegistry.register({ TestRenderer });
      setupRendererDom('renderer-void');

      renderComponent('renderer-void');
      renderComponent('renderer-void');

      expect(renderer).toHaveBeenCalledTimes(2);
      expect(() => runPageUnload()).not.toThrow();
    });

    it('does not treat a returned component-like function as a teardown', () => {
      const ReturnedComponent = jest.fn(() => React.createElement('div', null, 'legacy component result'));
      const TestRenderer: RendererFunction = (_props, _railsContext, _domNodeId) => ReturnedComponent;
      ComponentRegistry.register({ TestRenderer });
      setupRendererDom('renderer-component-result');

      renderComponent('renderer-component-result');
      runPageUnload();

      expect(ReturnedComponent).not.toHaveBeenCalled();
    });

    it('runs a teardown returned asynchronously by the renderer', async () => {
      const teardown = jest.fn();
      const TestRenderer: RendererFunction = (_props, _railsContext, _domNodeId) =>
        Promise.resolve({ teardown });
      ComponentRegistry.register({ TestRenderer });
      setupRendererDom('renderer-async');

      renderComponent('renderer-async');
      // Let the renderer's promise resolve so the teardown is captured.
      await Promise.resolve();

      runPageUnload();
      expect(teardown).toHaveBeenCalledTimes(1);
    });

    it('logs (and swallows) when an async teardown rejects on unmount', async () => {
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
      const rejection = new Error('async teardown boom');
      // The renderer returns a teardown wrapper synchronously; the teardown itself returns a rejecting
      // promise. This exercises invokeRendererTeardown's rejection-swallowing path (the reason it
      // wraps the call in Promise.resolve(...).catch) so the failure is logged, not left as an
      // unhandled rejection.
      const teardown = jest.fn(() => Promise.reject(rejection));
      const TestRenderer: RendererFunction = (_props, _railsContext, _domNodeId) => ({ teardown });
      ComponentRegistry.register({ TestRenderer });
      setupRendererDom('renderer-async-teardown-reject');

      renderComponent('renderer-async-teardown-reject');

      runPageUnload();
      expect(teardown).toHaveBeenCalledTimes(1);

      // Flush microtasks so the swallowing .catch runs.
      await new Promise((resolve) => {
        setTimeout(resolve, 0);
      });
      expect(consoleErrorSpy).toHaveBeenCalledWith(
        'Error in renderer teardown for dom node "renderer-async-teardown-reject":',
        rejection,
      );
      consoleErrorSpy.mockRestore();
    });

    it('continues running other teardowns when one teardown throws on unmount', () => {
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
      const throwingTeardown = jest.fn(() => {
        throw new Error('teardown boom');
      });
      const okTeardown = jest.fn();
      const ThrowingRenderer: RendererFunction = (_props, _railsContext, _domNodeId) => ({
        teardown: throwingTeardown,
      });
      const OkRenderer: RendererFunction = (_props, _railsContext, _domNodeId) => ({ teardown: okTeardown });
      ComponentRegistry.register({ ThrowingRenderer, OkRenderer });
      // Insertion order matters: the throwing teardown runs first, so we prove cleanup of the
      // later-registered entry still happens.
      setupRendererDom('renderer-throws', 'ThrowingRenderer');
      setupRendererDom('renderer-ok', 'OkRenderer');

      renderComponent('renderer-throws');
      renderComponent('renderer-ok');

      expect(() => runPageUnload()).not.toThrow();
      expect(throwingTeardown).toHaveBeenCalledTimes(1);
      expect(okTeardown).toHaveBeenCalledTimes(1);
      // Renderer-owned teardown failures use the renderer label (tagged with the dom node id) so they
      // are greppable alongside the async-rejection path, regardless of whether the teardown threw
      // synchronously or rejected.
      expect(consoleErrorSpy).toHaveBeenCalledWith(
        'Error in renderer teardown for dom node "renderer-throws":',
        expect.any(Error),
      );

      consoleErrorSpy.mockRestore();
    });

    it('drops a still-pending async teardown when the node is replaced before it resolves', async () => {
      // Documents the core best-effort limitation (Pro handles this race): the first mount's async
      // teardown resolves only after the same-id node has been replaced, so it must NOT be attached
      // to or run against the new mount.
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
      const resolvers: Array<(result: { teardown: () => void }) => void> = [];
      const renderer = jest.fn();
      const AsyncRenderer: RendererFunction = (_props, _railsContext, _domNodeId) => {
        renderer();
        return new Promise<{ teardown: () => void }>((resolve) => {
          resolvers.push(resolve);
        });
      };
      ComponentRegistry.register({ AsyncRenderer });
      const node1 = setupRendererDom('renderer-stale', 'AsyncRenderer');

      renderComponent('renderer-stale');
      expect(renderer).toHaveBeenCalledTimes(1);

      // Replace the node and re-render the same id before the first renderer resolves.
      node1.remove();
      const node2 = document.createElement('div');
      node2.id = 'renderer-stale';
      document.body.appendChild(node2);
      renderComponent('renderer-stale');
      expect(renderer).toHaveBeenCalledTimes(2);

      // The first (now-stale) renderer finally resolves its teardown.
      const staleTeardown = jest.fn();
      resolvers[0]({ teardown: staleTeardown });
      await Promise.resolve();

      // The stale teardown was not attached to the replaced mount, so cleanup never runs it. The
      // drop is a documented best-effort limitation, surfaced via console.error so it stays
      // diagnosable as a leak.
      runPageUnload();
      expect(staleTeardown).not.toHaveBeenCalled();
      expect(consoleErrorSpy).toHaveBeenCalledWith(
        expect.stringContaining('resolved after the page or node was already cleaned up'),
      );
      consoleErrorSpy.mockRestore();
    });

    it('does not let a stale async renderer overwrite a newer same-id teardown', async () => {
      // setupRailsContext() is provided by the enclosing beforeEach; this test focuses on
      // teardown-race ordering rather than rendered output correctness, so no extra setup is needed.
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
      try {
        const resolvers: Array<(result: { teardown: () => void }) => void> = [];
        const AsyncRenderer: RendererFunction = (_props, _railsContext, _domNodeId) =>
          new Promise<{ teardown: () => void }>((resolve) => {
            resolvers.push(resolve);
          });
        ComponentRegistry.register({ AsyncRenderer });
        const node1 = setupRendererDom('renderer-stale-after-newer', 'AsyncRenderer');

        renderComponent('renderer-stale-after-newer');

        node1.remove();
        const node2 = document.createElement('div');
        node2.id = 'renderer-stale-after-newer';
        document.body.appendChild(node2);
        // Keep the original component descriptor in place to simulate a soft navigation replacing
        // only the mount node for this id.
        renderComponent('renderer-stale-after-newer');
        expect(resolvers).toHaveLength(2);

        const staleTeardown = jest.fn();
        const currentTeardown = jest.fn();
        // Resolve the newer renderer first so its teardown is attached to the active entry before
        // the stale renderer settles.
        resolvers[1]({ teardown: currentTeardown });
        await Promise.resolve();
        resolvers[0]({ teardown: staleTeardown });
        await Promise.resolve();

        runPageUnload();
        expect(currentTeardown).toHaveBeenCalledTimes(1);
        expect(staleTeardown).not.toHaveBeenCalled();
        expect(consoleErrorSpy).toHaveBeenCalledWith(
          expect.stringContaining('resolved after the page or node was already cleaned up'),
        );
      } finally {
        consoleErrorSpy.mockRestore();
      }
    });

    it('drops and logs about an async teardown when unmount races the renderer resolving', async () => {
      // Complements the happy-path async test above: here page unload fires BEFORE the
      // renderer's promise resolves, which is the actual race the core package cannot win (Pro does).
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
      const teardown = jest.fn();
      const TestRenderer: RendererFunction = (_props, _railsContext, _domNodeId) =>
        Promise.resolve({ teardown });
      ComponentRegistry.register({ TestRenderer });
      setupRendererDom('renderer-async-race');

      renderComponent('renderer-async-race');
      // Unmount before the renderer's promise resolves, so the tracked entry is cleared first.
      runPageUnload();

      // Let the renderer's promise resolve; the teardown can no longer attach to the cleared entry.
      await Promise.resolve();

      expect(teardown).not.toHaveBeenCalled();
      expect(consoleErrorSpy).toHaveBeenCalledWith(
        expect.stringContaining('resolved after the page or node was already cleaned up'),
      );
      consoleErrorSpy.mockRestore();
    });

    it('logs (and does not rethrow) when an async renderer rejects before returning a teardown', async () => {
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
      const rejection = new Error('renderer rejected');
      const renderer = jest
        .fn<Promise<{ teardown: () => void }> | void, []>()
        .mockImplementationOnce(() => Promise.reject<{ teardown: () => void }>(rejection))
        .mockImplementationOnce(() => {});
      const RejectingRenderer: RendererFunction = (_props, _railsContext, _domNodeId) => renderer();
      ComponentRegistry.register({ RejectingRenderer });
      setupRendererDom('renderer-reject', 'RejectingRenderer');

      expect(() => renderComponent('renderer-reject')).not.toThrow();

      // Flush microtasks so the tracking .catch runs.
      await new Promise((resolve) => {
        setTimeout(resolve, 0);
      });

      expect(consoleErrorSpy).toHaveBeenCalledWith(
        expect.stringContaining(
          'Renderer for dom node "renderer-reject" rejected; the component did not mount',
        ),
        rejection,
      );
      renderComponent('renderer-reject');
      expect(renderer).toHaveBeenCalledTimes(2);
      consoleErrorSpy.mockRestore();
    });

    it('suppresses a stale async renderer rejection after page unload already cleared the entry', async () => {
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
      try {
        const rejection = new Error('renderer rejected after unload');
        let rejectRenderer!: (error: Error) => void;
        const TestRenderer: RendererFunction = (_props, _railsContext, _domNodeId) =>
          new Promise<{ teardown: () => void }>((_resolve, reject) => {
            rejectRenderer = reject;
          });
        ComponentRegistry.register({ TestRenderer });
        setupRendererDom('renderer-reject-after-unload', 'TestRenderer');

        renderComponent('renderer-reject-after-unload');
        runPageUnload();
        rejectRenderer(rejection);

        // Flush microtasks so the tracking .catch runs.
        await new Promise((resolve) => {
          setTimeout(resolve, 0);
        });

        expect(consoleErrorSpy).not.toHaveBeenCalledWith(
          expect.stringContaining('Renderer for dom node "renderer-reject-after-unload" rejected'),
          rejection,
        );
      } finally {
        consoleErrorSpy.mockRestore();
      }
    });

    it('logs the failure but still re-renders when the previous teardown throws on node replacement', () => {
      // Covers the replaced-node catch in renderElement: a teardown that throws synchronously during
      // replacement is logged with the renderer label, and the new node is still rendered.
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
      const renderer = jest.fn();
      const throwingTeardown = jest.fn(() => {
        throw new Error('teardown boom');
      });
      const TestRenderer: RendererFunction = (_props, _railsContext, _domNodeId) => {
        renderer();
        return { teardown: throwingTeardown };
      };
      ComponentRegistry.register({ TestRenderer });
      const targetNode1 = setupRendererDom('renderer-replace-throws');

      renderComponent('renderer-replace-throws');
      expect(renderer).toHaveBeenCalledTimes(1);

      // Replace the node and re-render the same id; the old teardown throws during cleanup.
      targetNode1.remove();
      const targetNode2 = document.createElement('div');
      targetNode2.id = 'renderer-replace-throws';
      document.body.appendChild(targetNode2);

      expect(() => renderComponent('renderer-replace-throws')).not.toThrow();

      expect(throwingTeardown).toHaveBeenCalledTimes(1);
      // The new node was still rendered despite the cleanup failure.
      expect(renderer).toHaveBeenCalledTimes(2);
      expect(consoleErrorSpy).toHaveBeenCalledWith(
        'Error in renderer teardown for dom node "renderer-replace-throws":',
        expect.any(Error),
      );
      consoleErrorSpy.mockRestore();
    });

    it('captures a teardown returned via a non-native thenable', async () => {
      // Exercises the isThenable branch with a thenable that is NOT a native Promise — the case the
      // `Promise.resolve(result).then(...)` wrap exists for (a custom thenable may lack the chaining
      // helpers a native Promise has). Cast the thenable to Promise so it satisfies the async
      // teardown-result arm; at runtime trackRendererMount detects it via isThenable and adopts it
      // with Promise.resolve.
      const teardown = jest.fn();
      const TestRenderer: RendererFunction = (_props, _railsContext, _domNodeId) =>
        ({
          then(onFulfilled: (value: { teardown: () => void }) => void) {
            onFulfilled({ teardown });
          },
        }) as unknown as Promise<{ teardown: () => void }>;
      ComponentRegistry.register({ TestRenderer });
      setupRendererDom('renderer-thenable');

      renderComponent('renderer-thenable');
      // Flush through a macrotask: Promise.resolve(nonNativeThenable) first schedules thenable
      // assimilation, then the downstream handler captures the teardown.
      await new Promise((resolve) => {
        setTimeout(resolve, 0);
      });

      runPageUnload();
      expect(teardown).toHaveBeenCalledTimes(1);
    });
  });

  describe('reactOnRailsComponentLoaded', () => {
    it('is an alias for renderComponent', () => {
      setupRailsContext();

      // Should work the same as renderComponent
      expect(() => reactOnRailsComponentLoaded('test-component')).not.toThrow();
    });
  });

  describe('Issue #2210: Multiple calls to renderComponent', () => {
    it('skips already-rendered components to prevent hydration errors', () => {
      setupRailsContext();

      // Register a simple component
      const TestComponent: React.FC<{ message: string }> = ({ message }) =>
        React.createElement('div', null, `Hello, ${message}!`);

      ComponentRegistry.register({ TestComponent });

      // Setup DOM element with component data
      const componentElement = document.createElement('div');
      componentElement.className = 'js-react-on-rails-component';
      componentElement.setAttribute('data-component-name', 'TestComponent');
      componentElement.setAttribute('data-dom-id', 'test-component-2210');
      componentElement.textContent = JSON.stringify({ message: 'World' });
      document.body.appendChild(componentElement);

      // Create target DOM node
      const targetNode = document.createElement('div');
      targetNode.id = 'test-component-2210';
      document.body.appendChild(targetNode);

      // First call should render
      renderComponent('test-component-2210');
      expect(targetNode.innerHTML).toContain('Rendered:');

      // Get the mock to track additional calls
      const mockHydrateOrRender = require('../src/reactHydrateOrRender.ts').default as jest.Mock;
      const callCountAfterFirstRender = mockHydrateOrRender.mock.calls.length;

      // Second call to the same component should skip (not call render again)
      renderComponent('test-component-2210');

      // The mock should NOT have been called again for the same component
      expect(mockHydrateOrRender.mock.calls.length).toBe(callCountAfterFirstRender);
    });

    it('renders when DOM node is replaced (same id, new node)', () => {
      setupRailsContext();

      // Register a simple component
      const TestComponent: React.FC<{ message: string }> = ({ message }) =>
        React.createElement('div', null, `Hello, ${message}!`);

      ComponentRegistry.register({ TestComponent });

      // Setup DOM element with component data
      const componentElement = document.createElement('div');
      componentElement.className = 'js-react-on-rails-component';
      componentElement.setAttribute('data-component-name', 'TestComponent');
      componentElement.setAttribute('data-dom-id', 'test-component-replace');
      componentElement.textContent = JSON.stringify({ message: 'World' });
      document.body.appendChild(componentElement);

      // Create first target DOM node
      const targetNode1 = document.createElement('div');
      targetNode1.id = 'test-component-replace';
      document.body.appendChild(targetNode1);

      // First call should render
      renderComponent('test-component-replace');
      expect(targetNode1.innerHTML).toContain('Rendered:');

      // Get the mock to track calls
      const mockHydrateOrRender = require('../src/reactHydrateOrRender.ts').default as jest.Mock;
      const callCountAfterFirstRender = mockHydrateOrRender.mock.calls.length;

      // Simulate DOM node replacement (e.g., via async HTML injection)
      targetNode1.remove();
      const targetNode2 = document.createElement('div');
      targetNode2.id = 'test-component-replace';
      document.body.appendChild(targetNode2);

      // Second call should render the new node (not skip)
      renderComponent('test-component-replace');

      // The mock SHOULD have been called again for the replaced node
      expect(mockHydrateOrRender.mock.calls.length).toBe(callCountAfterFirstRender + 1);
      expect(targetNode2.innerHTML).toContain('Rendered:');
    });
  });

  describe('hydrate_on scheduling', () => {
    const setupScheduledComponentDom = (
      domId: string,
      hydrateOn: 'visible' | 'idle',
      serverRenderedHtml = '<div>Server rendered</div>',
    ): HTMLElement => {
      setupRailsContext();

      const TestComponent: React.FC<{ message: string }> = ({ message }) =>
        React.createElement('div', null, `Hello, ${message}!`);
      ComponentRegistry.register({ TestComponent });

      const componentElement = document.createElement('div');
      componentElement.className = 'js-react-on-rails-component';
      componentElement.setAttribute('data-component-name', 'TestComponent');
      componentElement.setAttribute('data-dom-id', domId);
      componentElement.setAttribute('data-hydrate-on', hydrateOn);
      componentElement.textContent = JSON.stringify({ message: 'World' });
      document.body.appendChild(componentElement);

      const targetNode = document.createElement('div');
      targetNode.id = domId;
      targetNode.innerHTML = serverRenderedHtml;
      document.body.appendChild(targetNode);

      return targetNode;
    };

    beforeEach(() => {
      runPageUnload();
      const mockHydrateOrRender = require('../src/reactHydrateOrRender.ts').default as jest.Mock;
      mockHydrateOrRender.mockClear();
    });

    afterEach(() => {
      const idleWindow = window as unknown as {
        requestIdleCallback?: unknown;
        cancelIdleCallback?: unknown;
      };
      const observerGlobal = globalThis as unknown as { IntersectionObserver?: unknown };
      delete idleWindow.requestIdleCallback;
      delete idleWindow.cancelIdleCallback;
      delete observerGlobal.IntersectionObserver;
    });

    it('waits for visible components to intersect before hydrating', () => {
      type ObserverCallback = ConstructorParameters<typeof IntersectionObserver>[0];
      const observerInstances: Array<{
        callback: ObserverCallback;
        disconnect: jest.Mock;
        observe: jest.Mock;
      }> = [];

      class MockIntersectionObserver {
        callback: ObserverCallback;

        disconnect = jest.fn();

        observe = jest.fn();

        constructor(callback: ObserverCallback) {
          this.callback = callback;
          observerInstances.push(this);
        }
      }

      Object.defineProperty(globalThis, 'IntersectionObserver', {
        configurable: true,
        value: MockIntersectionObserver,
      });

      setupScheduledComponentDom('hydrate-visible-unit', 'visible');
      const mockHydrateOrRender = require('../src/reactHydrateOrRender.ts').default as jest.Mock;

      renderComponent('hydrate-visible-unit');

      expect(mockHydrateOrRender).not.toHaveBeenCalled();
      expect(observerInstances).toHaveLength(1);
      expect(observerInstances[0].observe).toHaveBeenCalledWith(
        document.getElementById('hydrate-visible-unit'),
      );

      observerInstances[0].callback(
        [{ isIntersecting: true, intersectionRatio: 1 }] as IntersectionObserverEntry[],
        observerInstances[0] as unknown as IntersectionObserver,
      );

      expect(observerInstances[0].disconnect).toHaveBeenCalledTimes(1);
      expect(mockHydrateOrRender).toHaveBeenCalledTimes(1);
    });

    it('waits for idle callbacks before hydrating idle components', () => {
      const idleCallbacks: Array<() => void> = [];
      Object.defineProperty(window, 'requestIdleCallback', {
        configurable: true,
        value: jest.fn((callback: () => void) => {
          idleCallbacks.push(callback);
          return idleCallbacks.length;
        }),
      });
      Object.defineProperty(window, 'cancelIdleCallback', {
        configurable: true,
        value: jest.fn(),
      });

      setupScheduledComponentDom('hydrate-idle-unit', 'idle');
      const mockHydrateOrRender = require('../src/reactHydrateOrRender.ts').default as jest.Mock;

      renderComponent('hydrate-idle-unit');

      expect(mockHydrateOrRender).not.toHaveBeenCalled();
      expect(idleCallbacks).toHaveLength(1);

      idleCallbacks[0]();

      expect(mockHydrateOrRender).toHaveBeenCalledTimes(1);
    });

    it('renders empty visible roots on the next tick instead of observing a zero-size target', () => {
      jest.useFakeTimers();
      const observerConstructor = jest.fn();

      class MockIntersectionObserver {
        disconnect = jest.fn();

        observe = jest.fn();

        constructor() {
          observerConstructor();
        }
      }

      Object.defineProperty(globalThis, 'IntersectionObserver', {
        configurable: true,
        value: MockIntersectionObserver,
      });

      setupScheduledComponentDom('hydrate-visible-client-only', 'visible', '');
      const mockHydrateOrRender = require('../src/reactHydrateOrRender.ts').default as jest.Mock;

      renderComponent('hydrate-visible-client-only');

      expect(observerConstructor).not.toHaveBeenCalled();
      expect(mockHydrateOrRender).not.toHaveBeenCalled();

      jest.runOnlyPendingTimers();

      expect(mockHydrateOrRender).toHaveBeenCalledTimes(1);
      jest.useRealTimers();
    });

    it('cancels pending visible hydration on page unload', () => {
      type ObserverCallback = ConstructorParameters<typeof IntersectionObserver>[0];
      let observerCallback!: ObserverCallback;
      const disconnectMock = jest.fn();

      class MockIntersectionObserver {
        disconnect = disconnectMock;

        observe = jest.fn();

        constructor(callback: ObserverCallback) {
          observerCallback = callback;
        }
      }

      Object.defineProperty(globalThis, 'IntersectionObserver', {
        configurable: true,
        value: MockIntersectionObserver,
      });

      setupScheduledComponentDom('hydrate-visible-unload', 'visible');
      const mockHydrateOrRender = require('../src/reactHydrateOrRender.ts').default as jest.Mock;

      renderComponent('hydrate-visible-unload');
      runPageUnload();

      expect(disconnectMock).toHaveBeenCalledTimes(1);

      observerCallback(
        [{ isIntersecting: true, intersectionRatio: 1 }] as IntersectionObserverEntry[],
        {} as IntersectionObserver,
      );

      expect(mockHydrateOrRender).not.toHaveBeenCalled();
    });

    it.each([
      {
        label: 'Error instance',
        thrownValue: new Error('scheduled render boom'),
        expectedLoggedMessage: 'scheduled render boom',
        expectCause: false,
      },
      {
        label: 'thrown string',
        thrownValue: 'scheduled string boom',
        expectedLoggedMessage: 'scheduled string boom',
        expectCause: true,
      },
      {
        label: 'thrown null',
        thrownValue: null,
        expectedLoggedMessage: 'null',
        expectCause: true,
      },
      {
        label: 'frozen Error instance',
        thrownValue: Object.freeze(new Error('scheduled frozen boom')),
        expectedLoggedMessage: 'scheduled frozen boom',
        expectCause: false,
      },
    ])(
      'reports scheduled render errors without throwing from the deferred callback: $label',
      ({ thrownValue, expectedLoggedMessage, expectCause }) => {
        type ObserverCallback = ConstructorParameters<typeof IntersectionObserver>[0];
        let observerCallback!: ObserverCallback;
        const originalMessage = thrownValue instanceof Error ? thrownValue.message : undefined;
        const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
        const mockHydrateOrRender = require('../src/reactHydrateOrRender.ts').default as jest.Mock;
        mockHydrateOrRender.mockImplementationOnce(() => {
          throw thrownValue;
        });

        class MockIntersectionObserver {
          disconnect = jest.fn();

          observe = jest.fn();

          constructor(callback: ObserverCallback) {
            observerCallback = callback;
          }
        }

        Object.defineProperty(globalThis, 'IntersectionObserver', {
          configurable: true,
          value: MockIntersectionObserver,
        });

        setupScheduledComponentDom(
          `hydrate-visible-error-${expectedLoggedMessage.replace(/\s+/g, '-')}`,
          'visible',
        );
        renderComponent(`hydrate-visible-error-${expectedLoggedMessage.replace(/\s+/g, '-')}`);

        expect(() => {
          observerCallback(
            [{ isIntersecting: true, intersectionRatio: 1 }] as IntersectionObserverEntry[],
            {} as IntersectionObserver,
          );
        }).not.toThrow();

        expect(consoleErrorSpy).toHaveBeenCalledTimes(1);
        const loggedError = consoleErrorSpy.mock.calls[0][0] as ErrorWithCause;
        expect(loggedError).toBeInstanceOf(Error);
        expect(loggedError.message).toBe(expectedLoggedMessage);
        if (expectCause) {
          expect(loggedError.cause).toBe(thrownValue);
        }
        if (thrownValue instanceof Error) {
          expect(loggedError).toBe(thrownValue);
          expect(thrownValue.message).toBe(originalMessage);
        }

        consoleErrorSpy.mockRestore();
      },
    );

    it('warns when visible hydration falls back without IntersectionObserver', () => {
      jest.useFakeTimers();
      const consoleWarnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});
      setupScheduledComponentDom('hydrate-visible-fallback', 'visible');
      const mockHydrateOrRender = require('../src/reactHydrateOrRender.ts').default as jest.Mock;

      renderComponent('hydrate-visible-fallback');

      expect(consoleWarnSpy).toHaveBeenCalledWith('[react-on-rails] No IntersectionObserver.');
      expect(mockHydrateOrRender).not.toHaveBeenCalled();

      jest.runOnlyPendingTimers();
      expect(mockHydrateOrRender).toHaveBeenCalledTimes(1);

      consoleWarnSpy.mockRestore();
      jest.useRealTimers();
    });

    it('uses a short idle fallback delay when requestIdleCallback is unavailable', () => {
      jest.useFakeTimers();
      setupScheduledComponentDom('hydrate-idle-fallback', 'idle');
      const mockHydrateOrRender = require('../src/reactHydrateOrRender.ts').default as jest.Mock;

      renderComponent('hydrate-idle-fallback');

      jest.advanceTimersByTime(49);
      expect(mockHydrateOrRender).not.toHaveBeenCalled();

      jest.advanceTimersByTime(1);
      expect(mockHydrateOrRender).toHaveBeenCalledTimes(1);

      jest.useRealTimers();
    });

    it('logs scheduled cancellation errors with the scheduled label during node replacement', () => {
      const disconnectError = new Error('scheduled disconnect boom');
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});

      class MockIntersectionObserver {
        disconnect = jest.fn(() => {
          throw disconnectError;
        });

        observe = jest.fn();
      }

      Object.defineProperty(globalThis, 'IntersectionObserver', {
        configurable: true,
        value: MockIntersectionObserver,
      });

      const targetNode = setupScheduledComponentDom('hydrate-visible-replace-label', 'visible');
      renderComponent('hydrate-visible-replace-label');

      targetNode.remove();
      const replacementNode = document.createElement('div');
      replacementNode.id = 'hydrate-visible-replace-label';
      document.body.appendChild(replacementNode);

      expect(() => renderComponent('hydrate-visible-replace-label')).not.toThrow();
      expect(consoleErrorSpy).toHaveBeenCalledWith(
        'Error canceling scheduled render for dom node "hydrate-visible-replace-label":',
        disconnectError,
      );

      consoleErrorSpy.mockRestore();
    });

    it('re-observes a visible root that is detached and later reattached', () => {
      type ObserverCallback = ConstructorParameters<typeof IntersectionObserver>[0];
      const observerInstances: Array<{
        callback: ObserverCallback;
        disconnect: jest.Mock;
        observe: jest.Mock;
      }> = [];

      class MockIntersectionObserver {
        callback: ObserverCallback;

        disconnect = jest.fn();

        observe = jest.fn();

        constructor(callback: ObserverCallback) {
          this.callback = callback;
          observerInstances.push(this);
        }
      }

      Object.defineProperty(globalThis, 'IntersectionObserver', {
        configurable: true,
        value: MockIntersectionObserver,
      });

      const targetNode = setupScheduledComponentDom('hydrate-visible-reattach', 'visible');
      const mockHydrateOrRender = require('../src/reactHydrateOrRender.ts').default as jest.Mock;

      // First schedule: observer #1 observes the node, nothing hydrates yet.
      renderComponent('hydrate-visible-reattach');
      expect(observerInstances).toHaveLength(1);
      expect(mockHydrateOrRender).not.toHaveBeenCalled();

      // Detach the SAME node (e.g. Turbo cache restore / DOM move), then reattach it unchanged.
      targetNode.remove();
      document.body.appendChild(targetNode);

      // Re-running renderComponent on the reattached node must NOT hit the "already rendered" skip
      // path (the scheduled entry never mounted); it must cancel the stale schedule and re-observe.
      expect(() => renderComponent('hydrate-visible-reattach')).not.toThrow();
      expect(observerInstances).toHaveLength(2);
      // The stale observer from the first schedule was cancelled.
      expect(observerInstances[0].disconnect).toHaveBeenCalledTimes(1);
      expect(observerInstances[1].observe).toHaveBeenCalledWith(targetNode);
      expect(mockHydrateOrRender).not.toHaveBeenCalled();

      // The fresh observer now drives hydration when the node becomes visible.
      observerInstances[1].callback(
        [
          { isIntersecting: true, intersectionRatio: 1, target: targetNode },
        ] as unknown as IntersectionObserverEntry[],
        observerInstances[1] as unknown as IntersectionObserver,
      );
      expect(mockHydrateOrRender).toHaveBeenCalledTimes(1);
    });

    it('drops a scheduled visible root when the observed target is detached', () => {
      type ObserverCallback = ConstructorParameters<typeof IntersectionObserver>[0];
      const observerInstances: Array<{
        callback: ObserverCallback;
        disconnect: jest.Mock;
        observe: jest.Mock;
      }> = [];

      class MockIntersectionObserver {
        callback: ObserverCallback;

        disconnect = jest.fn();

        observe = jest.fn();

        constructor(callback: ObserverCallback) {
          this.callback = callback;
          observerInstances.push(this);
        }
      }

      Object.defineProperty(globalThis, 'IntersectionObserver', {
        configurable: true,
        value: MockIntersectionObserver,
      });

      const targetNode = setupScheduledComponentDom('hydrate-visible-detached-drop', 'visible');
      const mockHydrateOrRender = require('../src/reactHydrateOrRender.ts').default as jest.Mock;

      renderComponent('hydrate-visible-detached-drop');
      expect(observerInstances).toHaveLength(1);
      expect(mockHydrateOrRender).not.toHaveBeenCalled();

      targetNode.remove();
      observerInstances[0].callback(
        [
          { isIntersecting: false, intersectionRatio: 0, target: targetNode },
        ] as unknown as IntersectionObserverEntry[],
        observerInstances[0] as unknown as IntersectionObserver,
      );

      expect(observerInstances[0].disconnect).toHaveBeenCalledTimes(1);
      expect(mockHydrateOrRender).not.toHaveBeenCalled();

      const replacementNode = document.createElement('div');
      replacementNode.id = 'hydrate-visible-detached-drop';
      replacementNode.innerHTML = '<div>Replacement server rendered</div>';
      document.body.appendChild(replacementNode);

      renderComponent('hydrate-visible-detached-drop');

      expect(observerInstances).toHaveLength(2);
      expect(observerInstances[0].disconnect).toHaveBeenCalledTimes(1);
      expect(observerInstances[1].observe).toHaveBeenCalledWith(replacementNode);
      expect(mockHydrateOrRender).not.toHaveBeenCalled();
    });
  });

  describe('page unload cleanup (React-root cleanup)', () => {
    beforeEach(() => {
      // Isolate from roots tracked by earlier tests.
      runPageUnload();
      setupRailsContext();
    });

    it('unmounts the framework-created React root on page unload', () => {
      const TestComponent: React.FC<{ message: string }> = ({ message }) =>
        React.createElement('div', null, `Hello, ${message}!`);
      ComponentRegistry.register({ TestComponent });

      const componentElement = document.createElement('div');
      componentElement.className = 'js-react-on-rails-component';
      componentElement.setAttribute('data-component-name', 'TestComponent');
      componentElement.setAttribute('data-dom-id', 'root-unmount');
      componentElement.textContent = JSON.stringify({ message: 'World' });
      document.body.appendChild(componentElement);

      const targetNode = document.createElement('div');
      targetNode.id = 'root-unmount';
      document.body.appendChild(targetNode);

      // Drive the React 18+ Root API branch in teardownEntry: return a root object whose unmount we
      // can assert on. The default mock returns undefined, so that branch is otherwise never
      // exercised and a regression breaking root unmount on page unload would pass unnoticed.
      const rootUnmount = jest.fn();
      const mockHydrateOrRender = require('../src/reactHydrateOrRender.ts').default as jest.Mock;
      mockHydrateOrRender.mockReturnValueOnce({ render: jest.fn(), unmount: rootUnmount });

      renderComponent('root-unmount');
      expect(rootUnmount).not.toHaveBeenCalled();

      runPageUnload();
      expect(rootUnmount).toHaveBeenCalledTimes(1);
    });

    it('unmounts the previous React root when the same dom id node is replaced', () => {
      // The renderer suite covers teardown-on-replacement; this covers the `kind: 'react'` arm of
      // teardownEntry on the replacement path. The default reactHydrateOrRender mock returns
      // undefined, so inject a root with an unmount spy — otherwise a regression dropping the
      // old-root unmount on replacement (re-introducing the original leak for React-root mounts)
      // would pass unnoticed.
      const TestComponent: React.FC<{ message: string }> = ({ message }) =>
        React.createElement('div', null, `Hello, ${message}!`);
      ComponentRegistry.register({ TestComponent });

      const componentElement = document.createElement('div');
      componentElement.className = 'js-react-on-rails-component';
      componentElement.setAttribute('data-component-name', 'TestComponent');
      componentElement.setAttribute('data-dom-id', 'root-replace');
      componentElement.textContent = JSON.stringify({ message: 'World' });
      document.body.appendChild(componentElement);

      const targetNode1 = document.createElement('div');
      targetNode1.id = 'root-replace';
      document.body.appendChild(targetNode1);

      const rootUnmount = jest.fn();
      const mockHydrateOrRender = require('../src/reactHydrateOrRender.ts').default as jest.Mock;
      mockHydrateOrRender.mockReturnValue({ render: jest.fn(), unmount: rootUnmount });

      renderComponent('root-replace');
      expect(rootUnmount).not.toHaveBeenCalled();

      // Replace the dom node (e.g. async HTML injection) and re-render the same id.
      targetNode1.remove();
      const targetNode2 = document.createElement('div');
      targetNode2.id = 'root-replace';
      document.body.appendChild(targetNode2);

      renderComponent('root-replace');

      // The old root was unmounted during replacement, and a new root was created for the new node.
      expect(rootUnmount).toHaveBeenCalledTimes(1);
      expect(mockHydrateOrRender).toHaveBeenCalledTimes(2);
    });
  });

  // Issue #4572: deferred hydration can bind a shared Redux store to a re-created instance
  describe('store re-initialization guard (issue #4572)', () => {
    beforeEach(() => {
      runPageUnload();
      setupRailsContext();
      StoreRegistry.clearHydratedStores();
      StoreRegistry.clearStoreGenerators();
    });

    afterEach(() => {
      StoreRegistry.clearHydratedStores();
      StoreRegistry.clearStoreGenerators();
    });

    const setupStoreElement = (storeName: string, props: Record<string, unknown>): void => {
      // Use a div element with the store attribute, matching how forEachStore queries for stores
      // (it queries by attribute, not by element type)
      const storeElement = document.createElement('div');
      storeElement.setAttribute('data-js-react-on-rails-store', storeName);
      storeElement.textContent = JSON.stringify(props);
      document.body.appendChild(storeElement);
    };

    it('does not re-create an already-hydrated store when forEachStore runs again', () => {
      const storeGenerator = jest.fn((props: Record<string, unknown>) => ({
        getState: () => ({ count: (props as { initialCount: number }).initialCount }),
        dispatch: jest.fn(),
        subscribe: jest.fn(),
      }));
      StoreRegistry.register({ SharedStore: storeGenerator });
      setupStoreElement('SharedStore', { initialCount: 42 });

      const TestComponent: React.FC = () => React.createElement('div', null, 'Test');
      ComponentRegistry.register({ TestComponent });

      // Setup a component that will trigger forEachStore
      const componentElement = document.createElement('div');
      componentElement.className = 'js-react-on-rails-component';
      componentElement.setAttribute('data-component-name', 'TestComponent');
      componentElement.setAttribute('data-dom-id', 'store-guard-test');
      componentElement.textContent = JSON.stringify({});
      document.body.appendChild(componentElement);

      const targetNode = document.createElement('div');
      targetNode.id = 'store-guard-test';
      document.body.appendChild(targetNode);

      // First render: creates the store
      renderComponent('store-guard-test');
      expect(storeGenerator).toHaveBeenCalledTimes(1);
      const firstStore = StoreRegistry.getStore('SharedStore');

      // Simulate a Turbo Frame or async content load that triggers another renderComponent
      // This should NOT re-create the store
      renderComponent('store-guard-test');
      expect(storeGenerator).toHaveBeenCalledTimes(1);
      const secondStore = StoreRegistry.getStore('SharedStore');

      // The store instance should be the same
      expect(firstStore).toBe(secondStore);
    });

    it('prevents store divergence between immediate and deferred components', () => {
      type ObserverCallback = ConstructorParameters<typeof IntersectionObserver>[0];
      const observerInstances: Array<{
        callback: ObserverCallback;
        disconnect: jest.Mock;
        observe: jest.Mock;
      }> = [];

      class MockIntersectionObserver {
        callback: ObserverCallback;

        disconnect = jest.fn();

        observe = jest.fn();

        constructor(callback: ObserverCallback) {
          this.callback = callback;
          observerInstances.push(this);
        }
      }

      Object.defineProperty(globalThis, 'IntersectionObserver', {
        configurable: true,
        value: MockIntersectionObserver,
      });

      let storeCallCount = 0;
      const stores: Array<{ id: number }> = [];
      const storeGenerator = jest.fn(() => {
        storeCallCount += 1;
        const store = {
          id: storeCallCount,
          getState: () => ({ storeId: storeCallCount }),
          dispatch: jest.fn(),
          subscribe: jest.fn(),
        };
        stores.push(store);
        return store;
      });
      StoreRegistry.register({ SharedStore: storeGenerator });
      setupStoreElement('SharedStore', {});

      const TestComponent: React.FC = () => React.createElement('div', null, 'Test');
      ComponentRegistry.register({ TestComponent });

      // Setup immediate component
      const immediateComponentEl = document.createElement('div');
      immediateComponentEl.className = 'js-react-on-rails-component';
      immediateComponentEl.setAttribute('data-component-name', 'TestComponent');
      immediateComponentEl.setAttribute('data-dom-id', 'immediate-comp');
      immediateComponentEl.setAttribute('data-hydrate-on', 'immediate');
      immediateComponentEl.textContent = JSON.stringify({});
      document.body.appendChild(immediateComponentEl);

      const immediateTargetNode = document.createElement('div');
      immediateTargetNode.id = 'immediate-comp';
      immediateTargetNode.innerHTML = '<div>Server rendered</div>';
      document.body.appendChild(immediateTargetNode);

      // Setup visible (deferred) component
      const visibleComponentEl = document.createElement('div');
      visibleComponentEl.className = 'js-react-on-rails-component';
      visibleComponentEl.setAttribute('data-component-name', 'TestComponent');
      visibleComponentEl.setAttribute('data-dom-id', 'visible-comp');
      visibleComponentEl.setAttribute('data-hydrate-on', 'visible');
      visibleComponentEl.textContent = JSON.stringify({});
      document.body.appendChild(visibleComponentEl);

      const visibleTargetNode = document.createElement('div');
      visibleTargetNode.id = 'visible-comp';
      visibleTargetNode.innerHTML = '<div>Server rendered</div>';
      document.body.appendChild(visibleTargetNode);

      // First render: immediate component hydrates, visible is scheduled
      renderComponent('immediate-comp');
      renderComponent('visible-comp');

      // Store should be created once
      expect(storeGenerator).toHaveBeenCalledTimes(1);
      const storeAfterFirstRender = StoreRegistry.getStore('SharedStore');

      // Simulate async content load (e.g., Turbo Frame) triggering another forEachStore
      // This happens when reactOnRailsComponentLoaded is called for a new component
      const asyncComponentEl = document.createElement('div');
      asyncComponentEl.className = 'js-react-on-rails-component';
      asyncComponentEl.setAttribute('data-component-name', 'TestComponent');
      asyncComponentEl.setAttribute('data-dom-id', 'async-comp');
      asyncComponentEl.textContent = JSON.stringify({});
      document.body.appendChild(asyncComponentEl);

      const asyncTargetNode = document.createElement('div');
      asyncTargetNode.id = 'async-comp';
      document.body.appendChild(asyncTargetNode);

      // This would previously re-create the store
      renderComponent('async-comp');

      // Store should still be the same instance
      expect(storeGenerator).toHaveBeenCalledTimes(1);
      const storeAfterAsyncLoad = StoreRegistry.getStore('SharedStore');
      expect(storeAfterAsyncLoad).toBe(storeAfterFirstRender);

      // Now the visible component becomes visible
      observerInstances[0].callback(
        [{ isIntersecting: true, intersectionRatio: 1 }] as IntersectionObserverEntry[],
        observerInstances[0] as unknown as IntersectionObserver,
      );

      // The visible component should have gotten the same store instance
      // (we can't directly test the component's store reference, but we verify
      // the store wasn't re-created before the visible component mounted)
      expect(storeGenerator).toHaveBeenCalledTimes(1);
      expect(StoreRegistry.getStore('SharedStore')).toBe(storeAfterFirstRender);

      // Cleanup
      const observerGlobal = globalThis as unknown as { IntersectionObserver?: unknown };
      delete observerGlobal.IntersectionObserver;
    });

    it('clears stores on page unload so navigation re-initializes with new props', () => {
      const storeGenerator = jest.fn((props: Record<string, unknown>) => ({
        getState: () => ({ count: (props as { initialCount: number }).initialCount }),
        dispatch: jest.fn(),
        subscribe: jest.fn(),
      }));
      StoreRegistry.register({ NavigationStore: storeGenerator });
      setupStoreElement('NavigationStore', { initialCount: 1 });

      const TestComponent: React.FC = () => React.createElement('div', null, 'Test');
      ComponentRegistry.register({ TestComponent });

      const componentElement = document.createElement('div');
      componentElement.className = 'js-react-on-rails-component';
      componentElement.setAttribute('data-component-name', 'TestComponent');
      componentElement.setAttribute('data-dom-id', 'nav-store-test');
      componentElement.textContent = JSON.stringify({});
      document.body.appendChild(componentElement);

      const targetNode = document.createElement('div');
      targetNode.id = 'nav-store-test';
      document.body.appendChild(targetNode);

      // First page load: creates the store
      renderComponent('nav-store-test');
      expect(storeGenerator).toHaveBeenCalledTimes(1);
      const firstStore = StoreRegistry.getStore('NavigationStore');
      expect(firstStore?.getState()).toEqual({ count: 1 });

      // Simulate Turbo/Turbolinks page unload (this should clear stores)
      runPageUnload();

      // After page unload, the store should be cleared
      expect(StoreRegistry.getStore('NavigationStore', false)).toBeUndefined();

      // Simulate new page - clear DOM and set up fresh page content
      // This mimics what Turbo does: replace the entire page content
      document.body.innerHTML = '';
      document.head.innerHTML = '';
      setupRailsContext();
      setupStoreElement('NavigationStore', { initialCount: 100 });

      const newComponentElement = document.createElement('div');
      newComponentElement.className = 'js-react-on-rails-component';
      newComponentElement.setAttribute('data-component-name', 'TestComponent');
      newComponentElement.setAttribute('data-dom-id', 'nav-store-test-2');
      newComponentElement.textContent = JSON.stringify({});
      document.body.appendChild(newComponentElement);

      const newTargetNode = document.createElement('div');
      newTargetNode.id = 'nav-store-test-2';
      document.body.appendChild(newTargetNode);

      // Second page load: should create a NEW store with new props
      renderComponent('nav-store-test-2');
      expect(storeGenerator).toHaveBeenCalledTimes(2);
      const secondStore = StoreRegistry.getStore('NavigationStore');
      expect(secondStore?.getState()).toEqual({ count: 100 });

      // The stores should be different instances
      expect(secondStore).not.toBe(firstStore);
    });
  });
});
