/**
 * @jest-environment jsdom
 */

import * as React from 'react';
import { renderComponent, reactOnRailsComponentLoaded } from '../src/ClientRenderer.ts';
import ComponentRegistry from '../src/ComponentRegistry.ts';
import StoreRegistry from '../src/StoreRegistry.ts';
import * as pageLifecycle from '../src/pageLifecycle.ts';
import * as reactApis from '../src/reactApis.cts';
import type { RendererFunction } from '../src/types/index.ts';

const triggerPageUnload = (pageLifecycle as unknown as { __triggerPageUnload: () => Promise<void> })
  .__triggerPageUnload;
const unmountComponentAtNodeMock = reactApis.unmountComponentAtNode as jest.MockedFunction<
  typeof reactApis.unmountComponentAtNode
>;

// Mock React DOM methods since we're testing client-side rendering
jest.mock('../src/reactHydrateOrRender.ts', () => ({
  __esModule: true,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  default: jest.fn((domNode: Element, _reactElement: React.ReactElement) => {
    // eslint-disable-next-line no-param-reassign
    domNode.innerHTML = '<div>Rendered: test</div>';
  }),
}));

jest.mock('../src/reactApis.cts', () => ({
  __esModule: true,
  ...jest.requireActual('../src/reactApis.cts'),
  unmountComponentAtNode: jest.fn(),
}));

// Mock pageLifecycle so we can drive the unload sweep deterministically.
// In the real module, `runPageUnloadedCallbacks` is fired by Turbo events that
// jsdom doesn't emit. The stub captures every callback the framework registers
// via `onPageUnloaded` (notably `unmountAllComponents` from ClientRenderer) and
// exposes a `__triggerPageUnload` helper tests use to invoke them.
jest.mock('../src/pageLifecycle.ts', () => {
  // Mirror the real module's Set-backed semantics so the same callback can't
  // register twice. The framework registers `unmountAllComponents` once at
  // module load; this mock does not drain callbacks because the describe-block
  // `afterEach` re-fires that idempotent callback to clear `renderedRoots`.
  // Tests that register additional unload callbacks should remove them in
  // their own teardown, or those callbacks will persist across tests.
  const unloadCallbacks = new Set<() => void | Promise<void>>();
  return {
    __esModule: true,
    onPageUnloaded: (cb: () => void | Promise<void>) => {
      unloadCallbacks.add(cb);
    },
    onPageLoaded: () => {
      // no-op: tests drive lifecycle via __triggerPageUnload only.
      // The real implementation fires immediately when currentPageState === 'load'.
    },
    refreshPageEventListeners: () => {
      // no-op: listener setup is not exercised in these unit tests.
    },
    __triggerPageUnload: async () => {
      for (const cb of [...unloadCallbacks]) {
        // eslint-disable-next-line no-await-in-loop
        await cb();
      }
    },
  };
});

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
    unmountComponentAtNodeMock.mockClear();
  });

  afterEach(() => {
    ComponentRegistry.clear();
    StoreRegistry.clearHydratedStores();
  });

  describe('renderComponent', () => {
    it('renders a simple React component', () => {
      // Setup Rails context
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
      // Setup Rails context
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

      // Test with non-existent DOM ID
      expect(() => renderComponent('non-existent-component')).not.toThrow();
    });

    // Renderer-function behaviour is covered in detail by the
    // `Renderer function teardown on unmount` describe block below — it
    // exercises invocation, the teardown contract, same-id replacement, and
    // the optional-teardown guard.

    it('unmounts non-renderer components when the render helper does not return a root', async () => {
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

      const TestComponent: React.FC = () => React.createElement('div', null, 'Hello');
      ComponentRegistry.register({ TestComponent });

      const componentElement = document.createElement('div');
      componentElement.className = 'js-react-on-rails-component';
      componentElement.setAttribute('data-component-name', 'TestComponent');
      componentElement.setAttribute('data-dom-id', 'test-component-no-root');
      componentElement.textContent = JSON.stringify({});
      document.body.appendChild(componentElement);

      const targetNode = document.createElement('div');
      targetNode.id = 'test-component-no-root';
      document.body.appendChild(targetNode);

      renderComponent('test-component-no-root');
      await triggerPageUnload();

      expect(unmountComponentAtNodeMock).toHaveBeenCalledWith(targetNode);
    });
  });

  describe('reactOnRailsComponentLoaded', () => {
    it('is an alias for renderComponent', () => {
      // Setup minimal Rails context
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

      // Should work the same as renderComponent
      expect(() => reactOnRailsComponentLoaded('test-component')).not.toThrow();
    });
  });

  describe('Issue #2210: Multiple calls to renderComponent', () => {
    const setupRailsContext = () => {
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

  describe('Renderer function teardown on unmount', () => {
    const setupRailsContext = () => {
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

    const setupRendererDom = (componentName: string, domId: string) => {
      const componentElement = document.createElement('div');
      componentElement.className = 'js-react-on-rails-component';
      componentElement.setAttribute('data-component-name', componentName);
      componentElement.setAttribute('data-dom-id', domId);
      componentElement.textContent = JSON.stringify({});
      document.body.appendChild(componentElement);

      const targetNode = document.createElement('div');
      targetNode.id = domId;
      document.body.appendChild(targetNode);
      return targetNode;
    };

    // Flush the framework's renderedRoots map between tests so a renderer
    // tracked in one test doesn't bleed into the next.
    afterEach(async () => {
      await triggerPageUnload();
      document.body.innerHTML = '';
    });

    it('invokes the teardown returned by a renderer function on page unload', async () => {
      setupRailsContext();

      const teardown = jest.fn();
      // Three explicit params so ComponentRegistry classifies this as `isRenderer`
      // (`renderFunction && component.length === 3`).
      const Renderer: RendererFunction = (_props, _railsContext, _domNodeId) => teardown;
      ComponentRegistry.register({ Renderer });
      setupRendererDom('Renderer', 'renderer-unload');

      renderComponent('renderer-unload');
      await triggerPageUnload();

      // The framework calls the renderer's teardown when the page unloads.
      expect(teardown).toHaveBeenCalledTimes(1);
    });

    it('invokes the teardown when the DOM node at the same domNodeId is replaced', () => {
      setupRailsContext();

      const teardown1 = jest.fn();
      const teardown2 = jest.fn();
      let nextTeardown: () => void = teardown1;

      const Renderer: RendererFunction = (_props, _railsContext, _domNodeId) => nextTeardown;
      ComponentRegistry.register({ Renderer });
      const target1 = setupRendererDom('Renderer', 'renderer-replace');

      renderComponent('renderer-replace');

      // Replace the DOM node at the same id (e.g. via async HTML injection).
      target1.remove();
      const target2 = document.createElement('div');
      target2.id = 'renderer-replace';
      document.body.appendChild(target2);

      nextTeardown = teardown2;
      renderComponent('renderer-replace');

      // The framework calls teardown1 before mounting on the new node;
      // teardown2 stays armed until the next unmount.
      expect(teardown1).toHaveBeenCalledTimes(1);
      expect(teardown2).toHaveBeenCalledTimes(0);
    });

    it('does not throw on page unload when the renderer returns nothing', async () => {
      setupRailsContext();

      const Renderer: RendererFunction = (_props, _railsContext, _domNodeId) => {
        // Returning a teardown is optional; not returning one is a no-op on unmount.
        return undefined;
      };
      ComponentRegistry.register({ Renderer });
      setupRendererDom('Renderer', 'renderer-noop');

      renderComponent('renderer-noop');

      await expect(triggerPageUnload()).resolves.not.toThrow();
    });

    it('does not treat objects with a non-function then property as renderer promises', () => {
      setupRailsContext();

      function Renderer(_props: unknown, _railsContext: unknown, _domNodeId: unknown) {
        return { then: 42 };
      }
      // Cast allows exercising invalid renderer output.
      ComponentRegistry.register({ Renderer: Renderer as unknown as RendererFunction });
      setupRendererDom('Renderer', 'renderer-non-promise-then');

      expect(() => renderComponent('renderer-non-promise-then')).not.toThrow();
    });

    it('invokes the teardown returned by an async renderer function on page unload', async () => {
      setupRailsContext();

      const teardown = jest.fn();
      // Async renderer: the framework awaits the renderer's promise and stores
      // the teardown it resolves to.
      const Renderer: RendererFunction = async (_props, _railsContext, _domNodeId) => teardown;
      ComponentRegistry.register({ Renderer });
      setupRendererDom('Renderer', 'renderer-async');

      renderComponent('renderer-async');
      // Yield to a macrotask, which by spec runs only after the entire pending
      // microtask queue is drained. So this also drains any chain of `await`s
      // the framework adds while unwrapping the renderer's returned promise
      // (each `await` schedules a microtask) before we check the teardown.
      await new Promise((resolve) => {
        setTimeout(resolve, 0);
      });
      await triggerPageUnload();

      expect(teardown).toHaveBeenCalledTimes(1);
    });

    it('invokes an async renderer teardown when page unload starts before the renderer promise resolves', async () => {
      setupRailsContext();

      const teardown = jest.fn();
      let resolveRenderer: (resolvedTeardown: () => void) => void;

      const Renderer: RendererFunction = (_props, _railsContext, _domNodeId) =>
        new Promise<() => void>((resolve) => {
          resolveRenderer = resolve;
        });
      ComponentRegistry.register({ Renderer });
      setupRendererDom('Renderer', 'renderer-async-unload-race');

      renderComponent('renderer-async-unload-race');
      const unloadPromise = triggerPageUnload();
      resolveRenderer!(teardown);

      await unloadPromise;

      expect(teardown).toHaveBeenCalledTimes(1);
    });

    it('waits for a pending async renderer teardown before rendering a replacement with the same domNodeId', async () => {
      setupRailsContext();

      const events: string[] = [];
      let renderCount = 0;
      let resolveFirstRenderer: (resolvedTeardown: () => void) => void;

      const Renderer: RendererFunction = (_props, _railsContext, _domNodeId) => {
        renderCount += 1;
        if (renderCount === 1) {
          return new Promise<() => void>((resolve) => {
            resolveFirstRenderer = resolve;
          });
        }

        events.push('second render');
        return () => {
          events.push('second teardown');
        };
      };
      ComponentRegistry.register({ Renderer });
      const target1 = setupRendererDom('Renderer', 'renderer-async-replace-race');

      renderComponent('renderer-async-replace-race');

      target1.remove();
      const target2 = document.createElement('div');
      target2.id = 'renderer-async-replace-race';
      document.body.appendChild(target2);

      renderComponent('renderer-async-replace-race');
      resolveFirstRenderer!(() => {
        events.push('first teardown');
      });
      await new Promise((resolve) => {
        setTimeout(resolve, 0);
      });

      expect(events).toEqual(['first teardown', 'second render']);
    });

    it('coalesces concurrent replacement renders while an async renderer teardown is pending', async () => {
      setupRailsContext();

      const events: string[] = [];
      let renderCount = 0;
      let resolveFirstRenderer: (resolvedTeardown: () => void) => void;

      const Renderer: RendererFunction = (_props, _railsContext, _domNodeId) => {
        renderCount += 1;
        if (renderCount === 1) {
          return new Promise<() => void>((resolve) => {
            resolveFirstRenderer = resolve;
          });
        }

        events.push(`render ${renderCount}`);
        return () => {
          events.push(`teardown ${renderCount}`);
        };
      };
      ComponentRegistry.register({ Renderer });
      const target1 = setupRendererDom('Renderer', 'renderer-async-replace-coalesce');

      renderComponent('renderer-async-replace-coalesce');

      target1.remove();
      const target2 = document.createElement('div');
      target2.id = 'renderer-async-replace-coalesce';
      document.body.appendChild(target2);
      renderComponent('renderer-async-replace-coalesce');

      target2.remove();
      const target3 = document.createElement('div');
      target3.id = 'renderer-async-replace-coalesce';
      document.body.appendChild(target3);
      renderComponent('renderer-async-replace-coalesce');

      resolveFirstRenderer!(() => {
        events.push('first teardown');
      });
      await new Promise((resolve) => {
        setTimeout(resolve, 0);
      });

      expect(renderCount).toBe(2);
      expect(events).toEqual(['first teardown', 'render 2']);
    });
  });
});
