/**
 * @jest-environment jsdom
 */

import * as React from 'react';
import { renderComponent, reactOnRailsComponentLoaded, unmountAllComponents } from '../src/ClientRenderer.ts';
import type { RenderFunction } from '../src/types/index.ts';
import ComponentRegistry from '../src/ComponentRegistry.ts';
import StoreRegistry from '../src/StoreRegistry.ts';

// Mock React DOM methods since we're testing client-side rendering
jest.mock('../src/reactHydrateOrRender.ts', () => ({
  __esModule: true,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  default: jest.fn((domNode: Element, _reactElement: React.ReactElement) => {
    // eslint-disable-next-line no-param-reassign
    domNode.innerHTML = '<div>Rendered: test</div>';
  }),
}));

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
  });

  // Issue #3209: renderer functions (the 3-arg `(props, railsContext, domNodeId)` form) own their
  // own mount. They may return a teardown callback so React on Rails can clean the mount up on
  // page unload (Turbo/Turbolinks navigation) or when the same dom-id node is replaced.
  describe('renderer functions (issue #3209: teardown cleanup)', () => {
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

    const setupRendererDom = (domId: string): HTMLElement => {
      const componentElement = document.createElement('div');
      componentElement.className = 'js-react-on-rails-component';
      componentElement.setAttribute('data-component-name', 'TestRenderer');
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
      unmountAllComponents();
      setupRailsContext();
    });

    it('invokes the renderer with props, railsContext, and domNodeId', () => {
      const renderer = jest.fn();
      // A 3-argument function is classified as a renderer by ComponentRegistry. The `RenderFunction`
      // annotation strips the parameter optionality at compile time only, so the arrow keeps its
      // runtime arity of 3.
      const TestRenderer: RenderFunction = (props, railsContext, domNodeId) => {
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

    it('runs the returned teardown on page unload (unmountAllComponents)', () => {
      const teardown = jest.fn();
      const renderer = jest.fn();
      const TestRenderer: RenderFunction = (props, railsContext, domNodeId) => {
        renderer(props, railsContext, domNodeId);
        return teardown;
      };
      ComponentRegistry.register({ TestRenderer });
      setupRendererDom('renderer-unload');

      renderComponent('renderer-unload');
      expect(renderer).toHaveBeenCalledTimes(1);
      expect(teardown).not.toHaveBeenCalled();

      // Simulate Turbo/Turbolinks page unload.
      unmountAllComponents();
      expect(teardown).toHaveBeenCalledTimes(1);
    });

    it('runs the previous teardown when the same dom id node is replaced', () => {
      const teardown = jest.fn();
      const renderer = jest.fn();
      const TestRenderer: RenderFunction = (props, railsContext, domNodeId) => {
        renderer(props, railsContext, domNodeId);
        return teardown;
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
      const TestRenderer: RenderFunction = (_props, _railsContext, _domNodeId) => {};
      ComponentRegistry.register({ TestRenderer });
      setupRendererDom('renderer-void');

      renderComponent('renderer-void');

      expect(() => unmountAllComponents()).not.toThrow();
    });

    it('runs a teardown returned asynchronously by the renderer', async () => {
      const teardown = jest.fn();
      const TestRenderer: RenderFunction = (_props, _railsContext, _domNodeId) => Promise.resolve(teardown);
      ComponentRegistry.register({ TestRenderer });
      setupRendererDom('renderer-async');

      renderComponent('renderer-async');
      // Let the renderer's promise resolve so the teardown is captured.
      await Promise.resolve();

      unmountAllComponents();
      expect(teardown).toHaveBeenCalledTimes(1);
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
});
