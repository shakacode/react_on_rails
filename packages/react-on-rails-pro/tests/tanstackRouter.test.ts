import * as React from 'react';
import { createRoot } from 'react-dom/client';
import { renderToString } from 'react-dom/server';
import {
  createTanStackRouterRenderFunction,
  serverRenderTanStackAppAsync,
} from '../src/tanstack-router/index.ts';
import type { RailsContext, ServerRenderResult } from 'react-on-rails/types';
import type { TanStackRouter } from '../src/tanstack-router/types.ts';

function buildRouter(): TanStackRouter {
  const state = {
    status: 'pending',
    location: {
      pathname: '/products',
      search: { category: 'tools' },
    },
    resolvedLocation: null,
    matches: [
      {
        id: '/products',
        updatedAt: 123,
        status: 'success',
        loaderData: { products: ['hammer'] },
        ssr: true,
      },
    ] as unknown[],
  };

  return {
    update: jest.fn(),
    load: jest.fn().mockResolvedValue(undefined),
    matchRoutes: jest
      .fn()
      .mockReturnValue([{ id: '/products', status: 'pending', updatedAt: 0, loaderData: undefined }]),
    __store: {
      setState: jest.fn((updater) => {
        const newState = updater(state as unknown as Record<string, unknown>);
        Object.assign(state, newState);
      }),
    },
    state,
    dehydrate: jest.fn().mockReturnValue({ matches: [{ id: 'products' }] }),
    hydrate: jest.fn(),
  };
}

type ActCallback = () => void | Promise<void>;

async function compatAct(callback: ActCallback): Promise<void> {
  const reactAct = (React as typeof React & { act?: (cb: ActCallback) => Promise<unknown> | unknown }).act;
  if (typeof reactAct !== 'function') {
    throw new Error('React.act is not available — React 18.3+ or 19+ is required');
  }
  await reactAct(callback);
}

describe('tanstack-router integration (Pro)', () => {
  it('returns a Promise with serverRenderHash on server-side render', async () => {
    const router = buildRouter();
    const options = {
      createRouter: () => router,
    };
    const deps = {
      RouterProvider: (_props: { router: TanStackRouter }) => React.createElement('div'),
      createMemoryHistory: jest.fn().mockReturnValue({
        location: {
          pathname: '/products',
          search: '?category=tools',
          hash: '',
          href: '/products?category=tools',
          state: null,
        },
      }),
      createBrowserHistory: jest.fn(),
    };

    const renderFn = createTanStackRouterRenderFunction(options, deps);

    const result = renderFn({ initial: 'prop' }, {
      serverSide: true,
      pathname: '/products',
      search: '?category=tools',
    } as unknown as RailsContext);

    // Server-side should return a Promise (async path)
    expect(result).toBeInstanceOf(Promise);

    const resolved = (await result) as ServerRenderResult;
    expect(renderFn.renderFunction).toBe(true);
    expect(React.isValidElement(resolved.renderedHtml)).toBe(true);
    expect(resolved.clientProps).toEqual({
      __tanstackRouterDehydratedState: {
        url: '/products?category=tools',
        dehydratedRouter: { matches: [{ id: 'products' }] },
        ssrRouter: {
          manifest: undefined,
          lastMatchId: '\u0000products',
          matches: [
            {
              i: '\u0000products',
              l: { products: ['hammer'] },
              s: 'success',
              ssr: true,
              u: 123,
            },
          ],
        },
      },
    });
    expect(deps.createMemoryHistory).toHaveBeenCalledWith({ initialEntries: ['/products?category=tools'] });
    expect(router.load).toHaveBeenCalled();
  });

  it('normalizes railsContext.search when it does not include a leading "?"', async () => {
    const router = buildRouter();
    const options = {
      createRouter: () => router,
    };
    const deps = {
      RouterProvider: (_props: { router: TanStackRouter }) => React.createElement('div'),
      createMemoryHistory: jest.fn().mockReturnValue({
        location: {
          pathname: '/products',
          search: '?category=tools',
          hash: '',
          href: '/products?category=tools',
          state: null,
        },
      }),
      createBrowserHistory: jest.fn(),
    };

    const renderFn = createTanStackRouterRenderFunction(options, deps);
    await renderFn({ initial: 'prop' }, {
      serverSide: true,
      pathname: '/products',
      search: 'category=tools',
    } as unknown as RailsContext);

    expect(deps.createMemoryHistory).toHaveBeenCalledWith({ initialEntries: ['/products?category=tools'] });
  });

  it('drops a bare "?" search string when building the server URL', async () => {
    const router = buildRouter();
    const options = {
      createRouter: () => router,
    };
    const deps = {
      RouterProvider: (_props: { router: TanStackRouter }) => React.createElement('div'),
      createMemoryHistory: jest.fn().mockReturnValue({
        location: {
          pathname: '/products',
          search: '',
          hash: '',
          href: '/products',
          state: null,
        },
      }),
      createBrowserHistory: jest.fn(),
    };

    const renderFn = createTanStackRouterRenderFunction(options, deps);
    await renderFn({ initial: 'prop' }, {
      serverSide: true,
      pathname: '/products',
      search: '?',
    } as unknown as RailsContext);

    expect(deps.createMemoryHistory).toHaveBeenCalledWith({ initialEntries: ['/products'] });
  });

  it('returns a client React component on client-side render', () => {
    const options = {
      createRouter: () => buildRouter(),
    };
    const deps = {
      RouterProvider: (_props: { router: TanStackRouter }) => React.createElement('div'),
      createMemoryHistory: jest.fn(),
      createBrowserHistory: jest.fn().mockReturnValue({
        location: {
          pathname: '/products',
          search: '?category=tools',
          hash: '',
          href: '/products?category=tools',
          state: null,
        },
      }),
    };

    const renderFn = createTanStackRouterRenderFunction(options, deps);
    const result = renderFn({}, {
      serverSide: false,
      pathname: '/products',
      search: '?category=tools',
    } as unknown as RailsContext);

    expect(typeof result).toBe('function');
  });

  it('renders RouterProvider (not RouterClient) on client hydration with SSR match data', () => {
    // Regression test: the old code used RouterClient when ssrRouter data existed.
    // RouterClient wraps RouterProvider in <Await> which suspends via defer(),
    // producing a component tree that differs from the server-rendered tree
    // (which uses RouterProvider directly), causing a React hydration mismatch.
    const router = buildRouter();

    const providerCalls: unknown[] = [];
    const clientCalls: unknown[] = [];
    const MockRouterProvider = (p: { router: TanStackRouter }) => {
      providerCalls.push(p);
      return React.createElement('div', { 'data-testid': 'provider' }, 'RouterProvider');
    };
    const MockRouterClient = (p: { router: TanStackRouter }) => {
      clientCalls.push(p);
      return React.createElement('div', { 'data-testid': 'client' }, 'RouterClient');
    };

    const renderFn = createTanStackRouterRenderFunction(
      { createRouter: () => router },
      {
        RouterProvider: MockRouterProvider,
        RouterClient: MockRouterClient,
        createMemoryHistory: jest.fn(),
        createBrowserHistory: jest.fn().mockReturnValue({
          location: {
            pathname: '/products',
            search: '?category=tools',
            hash: '',
            href: '/products?category=tools',
            state: null,
          },
        }),
      },
    );

    const props = {
      __tanstackRouterDehydratedState: {
        url: '/products?category=tools',
        dehydratedRouter: { matches: [{ id: 'products' }] },
        ssrRouter: {
          manifest: undefined,
          lastMatchId: '\u0000products',
          matches: [{ i: '\u0000products', l: { products: ['hammer'] }, s: 'success', ssr: true, u: 123 }],
        },
      },
    };
    const result = renderFn(props, {
      serverSide: false,
      pathname: '/products',
      search: '?category=tools',
    } as unknown as RailsContext);

    const html = renderToString(
      React.createElement(result as React.ComponentType<Record<string, unknown>>, props),
    );

    // The fix: RouterProvider is always used, matching the server-rendered tree.
    expect(html).toContain('RouterProvider');
    expect(html).not.toContain('RouterClient');
    expect(providerCalls.length).toBeGreaterThan(0);
    expect(clientCalls).toHaveLength(0);
  });

  it('injects SSR match data into router store to prevent Suspense suspension during hydration', () => {
    // Without synchronous match injection, the router's initial matches have
    // status='pending' and a loadPromise, causing MatchInner to throw (suspend).
    // The fix calls matchRoutes() + __store.setState() to make matches 'success'
    // before the first render, matching the fully-loaded server output.
    const setState = jest.fn();
    const router = buildRouter();
    router.matchRoutes = jest.fn().mockReturnValue([{ id: '/products', status: 'pending', updatedAt: 0 }]);
    router.__store = { setState };

    const renderFn = createTanStackRouterRenderFunction(
      { createRouter: () => router },
      {
        RouterProvider: (_: { router: TanStackRouter }) => React.createElement('div'),
        createMemoryHistory: jest.fn(),
        createBrowserHistory: jest.fn().mockReturnValue({
          location: { pathname: '/products', search: '', hash: '', href: '/products', state: null },
        }),
      },
    );

    const props = {
      __tanstackRouterDehydratedState: {
        url: '/products',
        dehydratedRouter: null,
        ssrRouter: {
          manifest: undefined,
          lastMatchId: '\u0000products',
          matches: [{ i: '\u0000products', l: { products: ['hammer'] }, s: 'success', u: 456 }],
        },
      },
    };
    const result = renderFn(props, {
      serverSide: false,
      pathname: '/products',
      search: '',
    } as unknown as RailsContext);

    // Trigger the render which initializes the router
    renderToString(React.createElement(result as React.ComponentType<Record<string, unknown>>, props));

    expect(router.matchRoutes).toHaveBeenCalledWith(router.state.location);
    expect(setState).toHaveBeenCalledTimes(1);

    // Verify the state updater applies SSR match data correctly
    const updater = setState.mock.calls[0][0] as (s: Record<string, unknown>) => Record<string, unknown>;
    const newState = updater({
      status: 'pending',
      location: '/products',
      matches: [{ id: '/products', status: 'pending' }],
    });
    expect(newState.status).toBe('idle');
    expect(newState.resolvedLocation).toBe('/products');
    expect((newState.matches as Array<Record<string, unknown>>)[0].status).toBe('success');
    expect((newState.matches as Array<Record<string, unknown>>)[0].loaderData).toEqual({
      products: ['hammer'],
    });
  });

  it('rehydrates nested route match IDs from \\0-separated to /-separated format', () => {
    // Pin the assumption that dehydrateSsrMatchId (serverRender.ts) uses \0 as
    // the segment separator and rehydrateMatchId (clientHydrate.ts) reverses it.
    // If TanStack Router's $_TSR wire format changes, this test will catch it.
    const setState = jest.fn();
    const router = buildRouter();
    router.state.location.pathname = '/products/42';
    router.matchRoutes = jest.fn().mockReturnValue([
      { id: '/products', status: 'pending', updatedAt: 0 },
      { id: '/products/$id', status: 'pending', updatedAt: 0 },
    ]);
    router.__store = { setState };

    const renderFn = createTanStackRouterRenderFunction(
      { createRouter: () => router },
      {
        RouterProvider: (_: { router: TanStackRouter }) => React.createElement('div'),
        createMemoryHistory: jest.fn(),
        createBrowserHistory: jest.fn().mockReturnValue({
          location: { pathname: '/products/42', search: '', hash: '', href: '/products/42', state: null },
        }),
      },
    );

    const props = {
      __tanstackRouterDehydratedState: {
        url: '/products/42',
        dehydratedRouter: null,
        ssrRouter: {
          manifest: undefined,
          lastMatchId: '\u0000products\u0000$id',
          matches: [
            { i: '\u0000products', l: { list: true }, s: 'success', u: 100 },
            { i: '\u0000products\u0000$id', l: { product: { id: 42 } }, s: 'success', u: 200 },
          ],
        },
      },
    };
    const result = renderFn(props, {
      serverSide: false,
      pathname: '/products/42',
      search: '',
    } as unknown as RailsContext);

    renderToString(React.createElement(result as React.ComponentType<Record<string, unknown>>, props));

    expect(setState).toHaveBeenCalledTimes(1);

    const updater = setState.mock.calls[0][0] as (s: Record<string, unknown>) => Record<string, unknown>;
    const newState = updater({
      status: 'pending',
      location: '/products/42',
      matches: [],
    });

    const matches = newState.matches as Array<Record<string, unknown>>;
    expect(matches).toHaveLength(2);
    // Verify nested route IDs were correctly rehydrated (\0 → /)
    expect(matches[0].id).toBe('/products');
    expect(matches[0].loaderData).toEqual({ list: true });
    expect(matches[0].status).toBe('success');
    expect(matches[1].id).toBe('/products/$id');
    expect(matches[1].loaderData).toEqual({ product: { id: 42 } });
    expect(matches[1].status).toBe('success');
  });

  it('does not pass __tanstackRouterDehydratedState through AppWrapper props', () => {
    const router = buildRouter();
    const observedProps: Array<Record<string, unknown>> = [];
    const options = {
      createRouter: () => router,
      AppWrapper: ({ children, ...rest }: { children?: React.ReactNode } & Record<string, unknown>) => {
        observedProps.push(rest);
        return React.createElement('section', null, children);
      },
    };
    const deps = {
      RouterProvider: (_props: { router: TanStackRouter }) => React.createElement('div'),
      createMemoryHistory: jest.fn(),
      createBrowserHistory: jest.fn().mockReturnValue({
        location: {
          pathname: '/products',
          search: '?category=tools',
          hash: '',
          href: '/products?category=tools',
          state: null,
        },
      }),
    };

    const renderFn = createTanStackRouterRenderFunction(options, deps);
    const props = {
      __tanstackRouterDehydratedState: {
        url: '/products?category=tools',
        dehydratedRouter: { matches: [{ id: 'products' }] },
      },
      userId: 42,
    };
    const result = renderFn(props, {
      serverSide: false,
      pathname: '/products',
      search: '?category=tools',
    } as unknown as RailsContext);

    renderToString(React.createElement(result as React.ComponentType<Record<string, unknown>>, props));

    expect(observedProps).toHaveLength(1);
    expect(observedProps[0]).toEqual({ userId: 42 });
  });

  it('sets router.ssr to { manifest: undefined } on the legacy hydration path', () => {
    const router = buildRouter();

    const options = {
      createRouter: () => router,
    };
    const deps = {
      RouterProvider: (_props: { router: TanStackRouter }) => React.createElement('div'),
      createMemoryHistory: jest.fn(),
      createBrowserHistory: jest.fn().mockReturnValue({
        location: {
          pathname: '/products',
          search: '?category=tools',
          hash: '',
          href: '/products?category=tools',
          state: null,
        },
      }),
    };

    const renderFn = createTanStackRouterRenderFunction(options, deps);
    const result = renderFn(
      {
        __tanstackRouterDehydratedState: {
          url: '/products?category=tools',
          dehydratedRouter: { matches: [{ id: 'products' }] },
        },
      },
      {
        serverSide: false,
        pathname: '/products',
        search: '?category=tools',
      } as unknown as RailsContext,
    );

    renderToString(
      React.createElement(result as React.ComponentType<Record<string, unknown>>, {
        __tanstackRouterDehydratedState: {
          url: '/products?category=tools',
          dehydratedRouter: { matches: [{ id: 'products' }] },
        },
      }),
    );

    expect(router.ssr).toEqual({ manifest: undefined });
  });

  it('clears router.ssr after the post-hydration legacy load settles', async () => {
    const router = buildRouter();
    let resolveLoad: (() => void) | undefined;
    router.load = jest.fn().mockImplementation(
      () =>
        new Promise<void>((resolve) => {
          resolveLoad = resolve;
        }),
    );

    const options = {
      createRouter: () => router,
    };
    const deps = {
      RouterProvider: (_props: { router: TanStackRouter }) => React.createElement('div'),
      createMemoryHistory: jest.fn(),
      createBrowserHistory: jest.fn().mockReturnValue({
        location: {
          pathname: '/products',
          search: '?category=tools',
          hash: '',
          href: '/products?category=tools',
          state: null,
        },
      }),
    };

    const renderFn = createTanStackRouterRenderFunction(options, deps);
    const props = {
      __tanstackRouterDehydratedState: {
        url: '/products?category=tools',
        dehydratedRouter: { matches: [{ id: 'products' }] },
      },
    };
    const clientApp = renderFn(props, {
      serverSide: false,
      pathname: '/products',
      search: '?category=tools',
    } as unknown as RailsContext);
    const container = document.createElement('div');
    const root = createRoot(container);

    await compatAct(async () => {
      root.render(React.createElement(clientApp as React.ComponentType<Record<string, unknown>>, props));
    });

    expect(router.load).toHaveBeenCalledTimes(1);
    expect(router.ssr).toEqual({ manifest: undefined });

    if (!resolveLoad) {
      throw new Error('Expected router.load to be invoked during hydration.');
    }

    await compatAct(async () => {
      resolveLoad?.();
      // Two ticks: one to settle .catch(), one to run .finally().
      await Promise.resolve();
      await Promise.resolve();
    });

    expect(router.ssr).toBeUndefined();

    await compatAct(async () => {
      root.unmount();
    });
  });

  it('preserves user-provided router.ssr after post-hydration load settles', async () => {
    const preconfiguredSsr = { manifest: { source: 'user' } };
    const router = buildRouter();
    router.ssr = preconfiguredSsr;

    let resolveLoad: (() => void) | undefined;
    router.load = jest.fn().mockImplementation(
      () =>
        new Promise<void>((resolve) => {
          resolveLoad = resolve;
        }),
    );

    const options = {
      createRouter: () => router,
    };
    const deps = {
      RouterProvider: (_props: { router: TanStackRouter }) => React.createElement('div'),
      createMemoryHistory: jest.fn(),
      createBrowserHistory: jest.fn().mockReturnValue({
        location: {
          pathname: '/products',
          search: '?category=tools',
          hash: '',
          href: '/products?category=tools',
          state: null,
        },
      }),
    };

    const renderFn = createTanStackRouterRenderFunction(options, deps);
    const props = {
      __tanstackRouterDehydratedState: {
        url: '/products?category=tools',
        dehydratedRouter: { matches: [{ id: 'products' }] },
      },
    };
    const clientApp = renderFn(props, {
      serverSide: false,
      pathname: '/products',
      search: '?category=tools',
    } as unknown as RailsContext);
    const container = document.createElement('div');
    const root = createRoot(container);

    await compatAct(async () => {
      root.render(React.createElement(clientApp as React.ComponentType<Record<string, unknown>>, props));
    });

    expect(router.load).toHaveBeenCalledTimes(1);
    expect(router.ssr).toBe(preconfiguredSsr);

    if (!resolveLoad) {
      throw new Error('Expected router.load to be invoked during hydration.');
    }

    await compatAct(async () => {
      resolveLoad?.();
      await Promise.resolve();
      await Promise.resolve();
    });

    expect(router.ssr).toBe(preconfiguredSsr);

    await compatAct(async () => {
      root.unmount();
    });
  });

  it('does not throw on client hydration when the SSR payload has no dehydrated router data', () => {
    const router = buildRouter();
    router.dehydrate = jest.fn().mockReturnValue(null);

    const options = {
      createRouter: () => router,
    };
    const deps = {
      RouterProvider: (_props: { router: TanStackRouter }) => React.createElement('div'),
      createMemoryHistory: jest.fn(),
      createBrowserHistory: jest.fn().mockReturnValue({
        location: {
          pathname: '/products',
          search: '',
          hash: '',
          href: '/products',
          state: null,
        },
      }),
    };

    const renderFn = createTanStackRouterRenderFunction(options, deps);
    const result = renderFn(
      {
        __tanstackRouterDehydratedState: {
          url: '/products',
          dehydratedRouter: null,
        },
      },
      {
        serverSide: false,
        pathname: '/products',
        search: null,
      } as unknown as RailsContext,
    );

    expect(() =>
      renderToString(
        React.createElement(result as React.ComponentType<Record<string, unknown>>, {
          __tanstackRouterDehydratedState: {
            url: '/products',
            dehydratedRouter: null,
            ssrRouter: {
              manifest: undefined,
              lastMatchId: '\u0000products',
              matches: [
                {
                  i: '\u0000products',
                  l: { products: ['hammer'] },
                  s: 'success',
                  ssr: true,
                  u: 123,
                },
              ],
            },
          },
        }),
      ),
    ).not.toThrow();
    expect(router.hydrate).not.toHaveBeenCalled();
  });

  it('treats a null SSR payload as absent during client hydration', () => {
    const router = buildRouter();

    const options = {
      createRouter: () => router,
    };
    const deps = {
      RouterProvider: (_props: { router: TanStackRouter }) => React.createElement('div'),
      createMemoryHistory: jest.fn(),
      createBrowserHistory: jest.fn().mockReturnValue({
        location: {
          pathname: '/products',
          search: '',
          hash: '',
          href: '/products',
          state: null,
        },
      }),
    };

    const renderFn = createTanStackRouterRenderFunction(options, deps);
    const result = renderFn(
      {
        __tanstackRouterDehydratedState: null,
      },
      {
        serverSide: false,
        pathname: '/products',
        search: null,
      } as unknown as RailsContext,
    );

    expect(() =>
      renderToString(
        React.createElement(result as React.ComponentType<Record<string, unknown>>, {
          __tanstackRouterDehydratedState: null,
        }),
      ),
    ).not.toThrow();
    expect(router.hydrate).not.toHaveBeenCalled();
    expect(router.ssr).toBeFalsy();
  });

  it('builds SSR match payloads even when router.dehydrate is unavailable', async () => {
    const router = buildRouter();
    delete router.dehydrate;

    const result = await serverRenderTanStackAppAsync(
      { createRouter: () => router },
      { initial: 'prop' },
      {
        serverSide: true,
        pathname: '/products',
        search: '',
      } as unknown as RailsContext & { serverSide: true },
      (_props: { router: TanStackRouter }) => React.createElement('div'),
      jest.fn().mockReturnValue({
        location: {
          pathname: '/products',
          search: '',
          hash: '',
          href: '/products',
          state: null,
        },
      }),
    );

    expect(result.dehydratedState.dehydratedRouter).toBeNull();
    expect(result.dehydratedState.ssrRouter).toEqual({
      manifest: undefined,
      lastMatchId: '\u0000products',
      matches: [
        {
          i: '\u0000products',
          l: { products: ['hammer'] },
          s: 'success',
          ssr: true,
          u: 123,
        },
      ],
    });
  });

  it('does not set router.ssr on the server (effects do not run during renderToString)', async () => {
    const router = buildRouter();

    const result = await serverRenderTanStackAppAsync(
      { createRouter: () => router },
      { initial: 'prop' },
      {
        serverSide: true,
        pathname: '/products',
        search: '?category=tools',
      } as unknown as RailsContext & { serverSide: true },
      (_props: { router: TanStackRouter }) => React.createElement('div'),
      jest.fn().mockReturnValue({
        location: {
          pathname: '/products',
          search: '?category=tools',
          hash: '',
          href: '/products?category=tools',
          state: null,
        },
      }),
    );

    expect(router.load).toHaveBeenCalled();
    expect(router.ssr).toBeUndefined();
    expect(result.dehydratedState).toEqual({
      url: '/products?category=tools',
      dehydratedRouter: { matches: [{ id: 'products' }] },
      ssrRouter: {
        manifest: undefined,
        lastMatchId: '\u0000products',
        matches: [
          {
            i: '\u0000products',
            l: { products: ['hammer'] },
            s: 'success',
            ssr: true,
            u: 123,
          },
        ],
      },
    });
  });
});
