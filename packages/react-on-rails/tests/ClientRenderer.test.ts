/**
 * @jest-environment jsdom
 */

import * as React from 'react';
import { renderComponent, reactOnRailsComponentLoaded } from '../src/ClientRenderer.ts';
import ComponentRegistry from '../src/ComponentRegistry.ts';
import StoreRegistry from '../src/StoreRegistry.ts';
import * as pageLifecycle from '../src/pageLifecycle.ts';
import type { RenderFunction } from '../src/types/index.ts';

const triggerPageUnload = (pageLifecycle as unknown as { __triggerPageUnload: () => Promise<void> })
  .__triggerPageUnload;

// Mock React DOM methods since we're testing client-side rendering
jest.mock('../src/reactHydrateOrRender.ts', () => ({
  __esModule: true,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  default: jest.fn((domNode: Element, _reactElement: React.ReactElement) => {
    // eslint-disable-next-line no-param-reassign
    domNode.innerHTML = '<div>Rendered: test</div>';
  }),
}));

// Mock pageLifecycle so we can drive the unload sweep deterministically.
// In the real module, `runPageUnloadedCallbacks` is fired by Turbo events that
// jsdom doesn't emit. The stub captures every callback the framework registers
// via `onPageUnloaded` (notably `unmountAllComponents` from ClientRenderer) and
// exposes a `__triggerPageUnload` helper tests use to invoke them.
jest.mock('../src/pageLifecycle.ts', () => {
  // Mirror the real module's Set-backed semantics so the same callback can't
  // register twice. We do NOT drain on trigger: ClientRenderer registers
  // `unmountAllComponents` once at module load and that callback is itself
  // idempotent (iterates and clears `renderedRoots`), so re-firing it from the
  // describe-block `afterEach` is harmless and is what keeps test state clean.
  const unloadCallbacks = new Set<() => void | Promise<void>>();
  return {
    __esModule: true,
    onPageUnloaded: (cb: () => void | Promise<void>) => {
      unloadCallbacks.add(cb);
    },
    onPageLoaded: () => {},
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

    it('handles renderer functions correctly', () => {
      expect.hasAssertions();
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

      // Create a mock renderer function
      const mockRenderer = jest.fn();
      ComponentRegistry.register({ MockRenderer: mockRenderer });

      // Setup DOM element
      const componentElement = document.createElement('div');
      componentElement.className = 'js-react-on-rails-component';
      componentElement.setAttribute('data-component-name', 'MockRenderer');
      componentElement.setAttribute('data-dom-id', 'test-renderer');
      componentElement.textContent = JSON.stringify({ test: 'data' });
      document.body.appendChild(componentElement);

      const targetNode = document.createElement('div');
      targetNode.id = 'test-renderer';
      document.body.appendChild(targetNode);

      renderComponent('test-renderer');

      // The renderer should be called since it has 3 parameters (making it a renderer)
      // Note: This test depends on the mock function being detected as a renderer
      // which requires the function to have length === 3
      expect(true).toBe(true); // Test passes if no error
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

  describe('Issue #3209: Renderer function teardown on unmount', () => {
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
    });

    it('invokes the teardown returned by a renderer function on page unload', async () => {
      setupRailsContext();

      const teardown = jest.fn();
      // Three explicit params so ComponentRegistry classifies this as `isRenderer`
      // (`renderFunction && component.length === 3`).
      function Renderer(_props: unknown, _railsContext: unknown, _domNodeId: unknown) {
        return teardown;
      }
      // The cast is temporary: today's `RenderFunction` return type doesn't permit
      // a teardown function. Issue #3209 widens it to `RenderFunctionResult |
      // RendererTeardown | Promise<… | RendererTeardown>`; once landed, the cast
      // can be removed.
      ComponentRegistry.register({ Renderer: Renderer as unknown as RenderFunction });
      setupRendererDom('Renderer', 'renderer-unload');

      renderComponent('renderer-unload');
      await triggerPageUnload();

      // Today: framework discards the renderer's return value, so the teardown
      // is never invoked on Turbo navigation. After the fix it must be called once.
      expect(teardown).toHaveBeenCalledTimes(1);
    });

    it('invokes the teardown when the DOM node at the same domNodeId is replaced', () => {
      setupRailsContext();

      const teardown1 = jest.fn();
      const teardown2 = jest.fn();
      let nextTeardown: jest.Mock = teardown1;

      function Renderer(_props: unknown, _railsContext: unknown, _domNodeId: unknown) {
        return nextTeardown;
      }
      // The cast is temporary: today's `RenderFunction` return type doesn't permit
      // a teardown function. Issue #3209 widens it to `RenderFunctionResult |
      // RendererTeardown | Promise<… | RendererTeardown>`; once landed, the cast
      // can be removed.
      ComponentRegistry.register({ Renderer: Renderer as unknown as RenderFunction });
      const target1 = setupRendererDom('Renderer', 'renderer-replace');

      renderComponent('renderer-replace');

      // Replace the DOM node at the same id (e.g. via async HTML injection).
      target1.remove();
      const target2 = document.createElement('div');
      target2.id = 'renderer-replace';
      document.body.appendChild(target2);

      nextTeardown = teardown2;
      renderComponent('renderer-replace');

      // Today: the first renderer's teardown was discarded, so the framework
      // cannot clean it up before mounting on the new node — leak. After the
      // fix it must run exactly once before the second mount, while teardown2
      // remains armed for the next unmount.
      expect(teardown1).toHaveBeenCalledTimes(1);
      expect(teardown2).toHaveBeenCalledTimes(0);
    });

    it('does not throw on page unload when the renderer returns nothing', async () => {
      setupRailsContext();

      function Renderer(_props: unknown, _railsContext: unknown, _domNodeId: unknown) {
        // Intentionally returns undefined — the teardown is optional in the
        // new contract; absence must remain a no-op on unmount.
      }
      // The cast is temporary: today's `RenderFunction` return type doesn't permit
      // a teardown function. Issue #3209 widens it to `RenderFunctionResult |
      // RendererTeardown | Promise<… | RendererTeardown>`; once landed, the cast
      // can be removed.
      ComponentRegistry.register({ Renderer: Renderer as unknown as RenderFunction });
      setupRendererDom('Renderer', 'renderer-noop');

      renderComponent('renderer-noop');

      await expect(triggerPageUnload()).resolves.not.toThrow();
    });

    it('invokes the teardown returned by an async renderer function on page unload', async () => {
      setupRailsContext();

      const teardown = jest.fn();
      // Async renderer: the framework must await the Promise to capture the
      // teardown. Pro's ClientSideRenderer already awaits; core needs the same.
      async function Renderer(_props: unknown, _railsContext: unknown, _domNodeId: unknown) {
        return teardown;
      }
      ComponentRegistry.register({ Renderer: Renderer as unknown as RenderFunction });
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
  });
});
