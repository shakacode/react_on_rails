/**
 * @jest-environment jsdom
 */

import * as React from 'react';
import { resetRailsContext } from 'react-on-rails/context';
import type { RailsContext, RenderFunction } from 'react-on-rails/types';
import * as ComponentRegistry from '../src/ComponentRegistry.ts';
import * as StoreRegistry from '../src/StoreRegistry.ts';
import { renderOrHydrateComponent, hydrateStore, unmountAll } from '../src/ClientSideRenderer.ts';
import {
  clearDefaultRSCProviderFactory,
  setDefaultRSCProviderFactory,
} from '../src/defaultRSCProviderRegistry.ts';
import { RSC_ROUTE_SSR_FALSE_BAILOUT_DIGEST } from '../src/RSCRouteSSRFalseBailoutError.ts';

type DefaultRSCProviderFactoryArgs = Parameters<Parameters<typeof setDefaultRSCProviderFactory>[0]>[0];

jest.mock('react-on-rails/reactHydrateOrRender', () => ({
  __esModule: true,
  default: jest.fn(),
}));

describe('ClientSideRenderer', () => {
  const mockReactHydrateOrRender = jest.requireMock('react-on-rails/reactHydrateOrRender')
    .default as jest.Mock;

  beforeEach(() => {
    ComponentRegistry.clear();
    unmountAll();
    clearDefaultRSCProviderFactory();
    resetRailsContext();
    document.body.innerHTML = '';
    document.head.innerHTML = '';
    jest.clearAllMocks();
  });

  afterEach(() => {
    ComponentRegistry.clear();
    unmountAll();
    clearDefaultRSCProviderFactory();
    resetRailsContext();
  });

  function setupTestComponentDom(
    domId: string,
    mountHtml = '',
    { ssrIdentifierPrefix }: { ssrIdentifierPrefix?: string } = {},
  ): Element {
    const componentSpec = document.createElement('div');
    componentSpec.className = 'js-react-on-rails-component';
    componentSpec.setAttribute('data-component-name', 'TestComponent');
    componentSpec.setAttribute('data-dom-id', domId);
    if (ssrIdentifierPrefix) {
      componentSpec.setAttribute('data-ssr-identifier-prefix', ssrIdentifierPrefix);
    }
    componentSpec.textContent = JSON.stringify({ greeting: 'hello' });
    document.body.appendChild(componentSpec);

    const mountNode = document.createElement('div');
    mountNode.id = domId;
    mountNode.innerHTML = mountHtml;
    document.body.appendChild(mountNode);
    return componentSpec;
  }

  function expectRecoverableHandlerFromLastRender(): (error: unknown) => void {
    const hydrateOptions = mockReactHydrateOrRender.mock.calls.at(-1)?.[3] as
      | { onRecoverableError?: (error: unknown) => void }
      | undefined;
    const onRecoverableError = hydrateOptions?.onRecoverableError;
    expect(onRecoverableError).toEqual(expect.any(Function));
    return onRecoverableError as (error: unknown) => void;
  }

  function addRailsContext(railsContextProps: Record<string, unknown> = {}): void {
    const railsContext = document.createElement('div');
    railsContext.id = 'js-react-on-rails-context';
    railsContext.textContent = JSON.stringify({
      serverSide: false,
      rorPro: true,
      ...railsContextProps,
    });
    document.body.appendChild(railsContext);
  }

  function setupTestStoreDom(storeName: string): Element {
    const storeDataElement = document.createElement('div');
    storeDataElement.setAttribute('data-js-react-on-rails-store', storeName);
    storeDataElement.textContent = JSON.stringify({ key: 'value' });
    document.body.appendChild(storeDataElement);
    return storeDataElement;
  }

  it('does not cache a component renderer created before railsContext exists', async () => {
    ComponentRegistry.register({
      TestComponent: ({ greeting }: { greeting: string }) => React.createElement('div', null, greeting),
    });
    const componentSpec = setupTestComponentDom('dom-id-123');

    await renderOrHydrateComponent(componentSpec);
    expect(mockReactHydrateOrRender).not.toHaveBeenCalled();

    addRailsContext();
    await renderOrHydrateComponent(componentSpec);
    expect(mockReactHydrateOrRender).toHaveBeenCalledTimes(1);
  });

  it('does not cache a store renderer created before railsContext exists', async () => {
    const storeGenerator = jest.fn(() => ({ getState: () => ({}) }));
    StoreRegistry.register({ TestStore: storeGenerator });
    const storeElement = setupTestStoreDom('TestStore');

    await hydrateStore(storeElement);
    expect(storeGenerator).not.toHaveBeenCalled();

    addRailsContext();
    await hydrateStore(storeElement);
    expect(storeGenerator).toHaveBeenCalledTimes(1);
  });

  it('wraps ordinary non-renderer roots with the registered default RSC provider when RSC payload URL exists', async () => {
    const TestComponent = ({ greeting }: { greeting: string }) => React.createElement('div', null, greeting);
    const DefaultProviderMarker = ({
      children,
      domNodeId,
      payloadPath,
    }: {
      children?: React.ReactNode;
      domNodeId: string;
      payloadPath: unknown;
    }) => React.createElement('section', { domNodeId, payloadPath }, children);
    const defaultProviderFactory = jest.fn(
      ({ reactElement, railsContext, domNodeId }: DefaultRSCProviderFactoryArgs) =>
        React.createElement(
          DefaultProviderMarker,
          {
            domNodeId,
            payloadPath: railsContext.rscPayloadGenerationUrlPath,
          },
          reactElement,
        ),
    );
    ComponentRegistry.register({ TestComponent });
    const componentSpec = setupTestComponentDom('dom-id-123');
    addRailsContext({ rscPayloadGenerationUrlPath: '/rsc_payload' });
    setDefaultRSCProviderFactory(defaultProviderFactory);

    await renderOrHydrateComponent(componentSpec);

    expect(defaultProviderFactory).toHaveBeenCalledTimes(1);
    expect(defaultProviderFactory).toHaveBeenCalledWith(
      expect.objectContaining({
        domNodeId: 'dom-id-123',
        railsContext: expect.objectContaining({ rscPayloadGenerationUrlPath: '/rsc_payload' }),
      }),
    );
    expect(mockReactHydrateOrRender).toHaveBeenCalledTimes(1);
    const wrappedElement = mockReactHydrateOrRender.mock.calls[0][1] as React.ReactElement;
    expect(mockReactHydrateOrRender.mock.calls[0][3]).toEqual({ identifierPrefix: 'dom-id-123' });
    expect(wrappedElement.type).toBe(DefaultProviderMarker);
    expect(wrappedElement.props).toEqual(
      expect.objectContaining({
        domNodeId: 'dom-id-123',
        payloadPath: '/rsc_payload',
      }),
    );
  });

  it('does not wrap ordinary roots when railsContext has no RSC payload URL', async () => {
    const TestComponent = ({ greeting }: { greeting: string }) => React.createElement('div', null, greeting);
    const defaultProviderFactory = jest.fn(({ reactElement }: DefaultRSCProviderFactoryArgs) => reactElement);
    ComponentRegistry.register({ TestComponent });
    const componentSpec = setupTestComponentDom('dom-id-123');
    addRailsContext();
    setDefaultRSCProviderFactory(defaultProviderFactory);

    await renderOrHydrateComponent(componentSpec);

    expect(defaultProviderFactory).not.toHaveBeenCalled();
    expect(mockReactHydrateOrRender).toHaveBeenCalledTimes(1);
    const reactElement = mockReactHydrateOrRender.mock.calls[0][1] as React.ReactElement;
    expect(reactElement.type).toBe(TestComponent);
  });

  it('passes the bailout-aware recoverable handler for hydrated default-provider roots', async () => {
    const TestComponent = ({ greeting }: { greeting: string }) => React.createElement('div', null, greeting);
    const defaultProviderFactory = jest.fn(({ reactElement }: DefaultRSCProviderFactoryArgs) => reactElement);
    ComponentRegistry.register({ TestComponent });
    const componentSpec = setupTestComponentDom('dom-id-123', '<div>Server fallback</div>');
    addRailsContext({ rscPayloadGenerationUrlPath: '/rsc_payload' });
    setDefaultRSCProviderFactory(defaultProviderFactory);

    await renderOrHydrateComponent(componentSpec);

    expect(defaultProviderFactory).toHaveBeenCalledTimes(1);
    expect(mockReactHydrateOrRender).toHaveBeenCalledTimes(1);
    expect(mockReactHydrateOrRender.mock.calls[0][2]).toBe(true);
    expect(mockReactHydrateOrRender.mock.calls[0][3]).toEqual(
      expect.objectContaining({
        onRecoverableError: expect.any(Function),
      }),
    );
    expect(mockReactHydrateOrRender.mock.calls[0][3]).not.toHaveProperty('identifierPrefix');
  });

  it('passes identifierPrefix for hydrated default-provider roots when server markup used one', async () => {
    const TestComponent = ({ greeting }: { greeting: string }) => React.createElement('div', null, greeting);
    const defaultProviderFactory = jest.fn(({ reactElement }: DefaultRSCProviderFactoryArgs) => reactElement);
    ComponentRegistry.register({ TestComponent });
    const componentSpec = setupTestComponentDom('dom-id-123', '<div>Server fallback</div>', {
      ssrIdentifierPrefix: 'server-prefix-123',
    });
    addRailsContext({ rscPayloadGenerationUrlPath: '/rsc_payload' });
    setDefaultRSCProviderFactory(defaultProviderFactory);

    await renderOrHydrateComponent(componentSpec);

    expect(defaultProviderFactory).toHaveBeenCalledTimes(1);
    expect(mockReactHydrateOrRender).toHaveBeenCalledTimes(1);
    expect(mockReactHydrateOrRender.mock.calls[0][2]).toBe(true);
    expect(mockReactHydrateOrRender.mock.calls[0][3]).toEqual(
      expect.objectContaining({
        identifierPrefix: 'server-prefix-123',
        onRecoverableError: expect.any(Function),
      }),
    );
  });

  it('suppresses the RSCRoute ssr=false bailout digest in hydrated default-provider roots', async () => {
    const TestComponent = ({ greeting }: { greeting: string }) => React.createElement('div', null, greeting);
    const defaultProviderFactory = jest.fn(({ reactElement }: DefaultRSCProviderFactoryArgs) => reactElement);
    const globalWithReportError = globalThis as typeof globalThis & {
      reportError?: (error: unknown) => void;
    };
    const originalReportError = globalWithReportError.reportError;
    const reportErrorSpy = jest.fn();
    globalWithReportError.reportError = reportErrorSpy;
    const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => undefined);
    ComponentRegistry.register({ TestComponent });
    const componentSpec = setupTestComponentDom('dom-id-123', '<div>Server fallback</div>');
    addRailsContext({ rscPayloadGenerationUrlPath: '/rsc_payload' });
    setDefaultRSCProviderFactory(defaultProviderFactory);

    try {
      await renderOrHydrateComponent(componentSpec);

      const onRecoverableError = expectRecoverableHandlerFromLastRender();
      onRecoverableError({ digest: RSC_ROUTE_SSR_FALSE_BAILOUT_DIGEST });

      expect(reportErrorSpy).not.toHaveBeenCalled();
      expect(consoleErrorSpy).not.toHaveBeenCalled();
    } finally {
      globalWithReportError.reportError = originalReportError;
      consoleErrorSpy.mockRestore();
    }
  });

  it('reports non-bailout recoverable errors in hydrated default-provider roots', async () => {
    const TestComponent = ({ greeting }: { greeting: string }) => React.createElement('div', null, greeting);
    const defaultProviderFactory = jest.fn(({ reactElement }: DefaultRSCProviderFactoryArgs) => reactElement);
    const globalWithReportError = globalThis as typeof globalThis & {
      reportError?: (error: unknown) => void;
    };
    const originalReportError = globalWithReportError.reportError;
    const reportErrorSpy = jest.fn();
    globalWithReportError.reportError = reportErrorSpy;
    ComponentRegistry.register({ TestComponent });
    const componentSpec = setupTestComponentDom('dom-id-123', '<div>Server fallback</div>');
    addRailsContext({ rscPayloadGenerationUrlPath: '/rsc_payload' });
    setDefaultRSCProviderFactory(defaultProviderFactory);

    try {
      await renderOrHydrateComponent(componentSpec);

      const recoverableError = new Error('real recoverable hydration error');
      const onRecoverableError = expectRecoverableHandlerFromLastRender();
      onRecoverableError(recoverableError);

      expect(reportErrorSpy).toHaveBeenCalledTimes(1);
      expect(reportErrorSpy).toHaveBeenCalledWith(recoverableError);
    } finally {
      globalWithReportError.reportError = originalReportError;
    }
  });

  it('delegates renderer roots without wrapping them with the default RSC provider', async () => {
    const renderer = jest.fn();
    const TestRenderer: RenderFunction = (
      props?: Record<string, unknown>,
      railsContext?: RailsContext,
      domNodeId?: string,
    ) => {
      renderer(props, railsContext, domNodeId);
      return Promise.resolve('');
    };
    const defaultProviderFactory = jest.fn(({ reactElement }: DefaultRSCProviderFactoryArgs) => reactElement);
    ComponentRegistry.register({ TestComponent: TestRenderer });
    const componentSpec = setupTestComponentDom('dom-id-123');
    addRailsContext({ rscPayloadGenerationUrlPath: '/rsc_payload' });
    setDefaultRSCProviderFactory(defaultProviderFactory);

    await renderOrHydrateComponent(componentSpec);

    expect(renderer).toHaveBeenCalledTimes(1);
    expect(defaultProviderFactory).not.toHaveBeenCalled();
    expect(mockReactHydrateOrRender).not.toHaveBeenCalled();
  });

  // Issue #3209: a renderer function (3-arg form) owns its own mount and may return a teardown
  // callback so React on Rails can clean it up on unmount (Turbo navigation / node replacement).
  it('runs the teardown returned by a renderer when the component is unmounted', async () => {
    const teardown = jest.fn();
    const TestRenderer: RenderFunction = (
      _props?: Record<string, unknown>,
      _railsContext?: RailsContext,
      _domNodeId?: string,
    ) => teardown;
    ComponentRegistry.register({ TestComponent: TestRenderer });
    const componentSpec = setupTestComponentDom('dom-id-teardown');
    addRailsContext();

    await renderOrHydrateComponent(componentSpec);
    expect(teardown).not.toHaveBeenCalled();

    // Simulate Turbo/Turbolinks page unload.
    unmountAll();
    expect(teardown).toHaveBeenCalledTimes(1);

    // A second page-unload sweep must not re-run the teardown. unmountAll clears the tracked-roots
    // map, so the second sweep finds nothing — this guards against a regression where the map is not
    // cleared (the per-instance single-shot guard is unreachable via the public API once cleared).
    unmountAll();
    expect(teardown).toHaveBeenCalledTimes(1);
    expect(mockReactHydrateOrRender).not.toHaveBeenCalled();
  });

  it('runs a teardown returned asynchronously by a renderer on unmount', async () => {
    const teardown = jest.fn();
    const TestRenderer: RenderFunction = (
      _props?: Record<string, unknown>,
      _railsContext?: RailsContext,
      _domNodeId?: string,
    ) => Promise.resolve(teardown);
    ComponentRegistry.register({ TestComponent: TestRenderer });
    const componentSpec = setupTestComponentDom('dom-id-teardown-async');
    addRailsContext();

    await renderOrHydrateComponent(componentSpec);
    expect(teardown).not.toHaveBeenCalled();

    unmountAll();
    expect(teardown).toHaveBeenCalledTimes(1);
  });

  it('logs (and swallows) when an async teardown rejects on unmount', async () => {
    const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
    const rejection = new Error('async teardown boom');
    // The renderer returns a teardown synchronously; the teardown itself returns a rejecting
    // promise, exercising invokeRendererTeardown's rejection-swallowing path so the failure is
    // logged rather than left as an unhandled rejection.
    const teardown = jest.fn(() => Promise.reject(rejection));
    const TestRenderer: RenderFunction = (
      _props?: Record<string, unknown>,
      _railsContext?: RailsContext,
      _domNodeId?: string,
    ) => teardown;
    ComponentRegistry.register({ TestComponent: TestRenderer });
    const componentSpec = setupTestComponentDom('dom-id-teardown-async-reject');
    addRailsContext();

    await renderOrHydrateComponent(componentSpec);
    unmountAll();
    expect(teardown).toHaveBeenCalledTimes(1);

    // Flush microtasks so the swallowing .catch runs.
    await new Promise((resolve) => {
      setTimeout(resolve, 0);
    });
    expect(consoleErrorSpy).toHaveBeenCalledWith(
      'Error in renderer teardown for dom node "dom-id-teardown-async-reject":',
      rejection,
    );
    consoleErrorSpy.mockRestore();
  });

  it('rejects with a render error when an async renderer rejects before returning a teardown', async () => {
    const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
    const rejection = new Error('renderer rejected');
    // Unlike the core renderer (which logs and swallows the rejection), Pro awaits the renderer, so
    // a rejection propagates to render()'s outer catch and rejects the render promise with the
    // wrapped "encountered an error while rendering" message.
    // Parameterize reject as `<() => void>` so the rejected promise types as the renderer-teardown
    // arm of RenderFunction's return union (a bare Promise.reject resolves across both arms and
    // satisfies neither under ts-jest's type-check).
    const TestRenderer: RenderFunction = (
      _props?: Record<string, unknown>,
      _railsContext?: RailsContext,
      _domNodeId?: string,
    ) => Promise.reject<() => void>(rejection);
    ComponentRegistry.register({ TestComponent: TestRenderer });
    const componentSpec = setupTestComponentDom('dom-id-renderer-reject');
    addRailsContext();

    await expect(renderOrHydrateComponent(componentSpec)).rejects.toThrow(
      'ReactOnRails encountered an error while rendering component: TestComponent',
    );
    consoleErrorSpy.mockRestore();
  });

  it('does not throw on unmount when the renderer returns nothing', async () => {
    const TestRenderer: RenderFunction = (
      _props?: Record<string, unknown>,
      _railsContext?: RailsContext,
      _domNodeId?: string,
    ) => {
      // Legacy renderer that does not opt into cleanup.
    };
    ComponentRegistry.register({ TestComponent: TestRenderer });
    const componentSpec = setupTestComponentDom('dom-id-teardown-none');
    addRailsContext();

    await renderOrHydrateComponent(componentSpec);

    expect(() => unmountAll()).not.toThrow();
  });

  it('runs the teardown when unmount races an async renderer still resolving (issue #3209)', async () => {
    // Unlike the core renderer, Pro awaits the renderer and re-checks unmount state, so a teardown
    // that resolves after a Turbo navigation has already unmounted the mount is still run, not
    // leaked.
    const teardown = jest.fn();
    let resolveRenderer!: (value: () => void) => void;
    const rendererPromise = new Promise<() => void>((resolve) => {
      resolveRenderer = resolve;
    });
    const TestRenderer: RenderFunction = (
      _props?: Record<string, unknown>,
      _railsContext?: RailsContext,
      _domNodeId?: string,
    ) => rendererPromise;
    ComponentRegistry.register({ TestComponent: TestRenderer });
    const componentSpec = setupTestComponentDom('dom-id-teardown-race');
    addRailsContext();

    // Start rendering but do not await — the renderer's promise is still pending, so render() is
    // parked awaiting it.
    const renderPromise = renderOrHydrateComponent(componentSpec);
    await new Promise((resolve) => {
      setTimeout(resolve, 0);
    });

    // Simulate a Turbo/Turbolinks navigation unmounting the mount before the renderer resolves.
    unmountAll();
    expect(teardown).not.toHaveBeenCalled();

    // The renderer finally resolves; unmount() could not see the teardown, so render() runs it now.
    resolveRenderer(teardown);
    await renderPromise;

    expect(teardown).toHaveBeenCalledTimes(1);
  });

  it('logs (and does not reject) when a raced async renderer teardown throws synchronously', async () => {
    // Same race as above, but the resolved teardown throws synchronously. render() must guard the
    // call (like unmount() does) so the throw is logged rather than escaping render()'s outer catch,
    // which would reject renderPromise with a misleading "encountered an error while rendering" error
    // after the component is already unmounted.
    const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
    const teardownError = new Error('teardown boom');
    const teardown = jest.fn(() => {
      throw teardownError;
    });
    let resolveRenderer!: (value: () => void) => void;
    const rendererPromise = new Promise<() => void>((resolve) => {
      resolveRenderer = resolve;
    });
    const TestRenderer: RenderFunction = (
      _props?: Record<string, unknown>,
      _railsContext?: RailsContext,
      _domNodeId?: string,
    ) => rendererPromise;
    ComponentRegistry.register({ TestComponent: TestRenderer });
    const componentSpec = setupTestComponentDom('dom-id-teardown-race-throws');
    addRailsContext();

    const renderPromise = renderOrHydrateComponent(componentSpec);
    await new Promise((resolve) => {
      setTimeout(resolve, 0);
    });

    unmountAll();
    resolveRenderer(teardown);

    // The synchronous throw is caught and logged, so renderPromise resolves rather than rejecting.
    await expect(renderPromise).resolves.toBeUndefined();
    expect(teardown).toHaveBeenCalledTimes(1);
    expect(consoleErrorSpy).toHaveBeenCalledWith(
      'Error in renderer teardown for dom node "dom-id-teardown-race-throws":',
      teardownError,
    );
    consoleErrorSpy.mockRestore();
  });
});
