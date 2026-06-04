import * as React from 'react';
import {
  RouterProvider as ActualRouterProvider,
  createMemoryHistory as createActualMemoryHistory,
  createRootRoute,
  createRoute,
  createRouter as createActualRouter,
} from '@tanstack/react-router';
import { batch as tanstackStoreBatch, createAtom } from '@tanstack/store';
import { createRoot, hydrateRoot } from 'react-dom/client';
import { renderToString } from 'react-dom/server';
import { createTanStackRouterRenderFunction, serverRenderTanStackAppAsync } from '../src/tanstack-router.ts';
import type { RailsContext, ServerRenderResult } from 'react-on-rails/types';
import type { TanStackRouter } from '../src/tanstack-router/types.ts';

function buildRouter(): TanStackRouter {
  const productsRoute = { id: '/products' };
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
      .mockReturnValue([
        { id: '/products', routeId: '/products', status: 'pending', updatedAt: 0, loaderData: undefined },
      ]),
    __store: {
      setState: jest.fn((updater) => {
        const newState = updater(state as unknown as Record<string, unknown>);
        Object.assign(state, newState);
      }),
    },
    looseRoutesById: {
      '/products': productsRoute,
    },
    loadRouteChunk: undefined,
    state,
    options: {
      hydrate: jest.fn(),
    },
    dehydrate: jest.fn().mockReturnValue({ matches: [{ id: 'products' }] }),
    hydrate: jest.fn(),
  };
}

function buildActualTanStackRouter(): TanStackRouter {
  const RootLayout = () => React.createElement('div', null, React.createElement('main'));
  const ProductsPage = () => React.createElement('h1', null, 'Products');
  const rootRoute = createRootRoute({ component: RootLayout });
  const productsRoute = createRoute({
    getParentRoute: () => rootRoute,
    path: '/products',
    loader: () => ({ products: ['hammer'] }),
    component: ProductsPage,
  });
  const routeTree = rootRoute.addChildren([productsRoute]);

  return createActualRouter({
    routeTree,
    history: createActualMemoryHistory({ initialEntries: ['/products'] }),
  }) as unknown as TanStackRouter;
}

async function compatAct(callback: () => void | Promise<void>): Promise<void> {
  // React 19 exports act on the React object; React 18 exports it from react-dom/test-utils
  const actFn =
    typeof React.act === 'function'
      ? React.act
      : // eslint-disable-next-line @typescript-eslint/no-require-imports
        (require('react-dom/test-utils') as { act?: typeof React.act }).act;
  if (typeof actFn !== 'function') {
    throw new Error('act is not available — React 18 (react-dom/test-utils) or React 19+ is required');
  }
  await actFn(callback);
}

// `@tanstack/react-router`'s SSR helpers reference `globalThis.Response` (a Fetch
// API global that jest's jsdom environment does not always polyfill). Tests that
// exercise the real router in Node must stub it for the duration of the test
// and restore it afterwards, otherwise other tests inherit the stub.
async function withResponsePolyfill<T>(fn: () => Promise<T>): Promise<T> {
  const originalResponse = globalThis.Response;
  if (typeof originalResponse === 'undefined') {
    globalThis.Response = class Response {} as typeof Response;
  }
  try {
    return await fn();
  } finally {
    if (typeof originalResponse === 'undefined') {
      delete (globalThis as { Response?: typeof Response }).Response;
    } else {
      globalThis.Response = originalResponse;
    }
  }
}

function buildStoresHydrationHarness({
  useBatch = false,
  includeLegacyStore = false,
}: { useBatch?: boolean; includeLegacyStore?: boolean } = {}) {
  const router = buildRouter();
  if (!includeLegacyStore) {
    delete router.__store;
  }
  router.matchRoutes = jest.fn().mockReturnValue([{ id: '/products', status: 'pending', updatedAt: 0 }]);

  const storeState = {
    status: createAtom<'idle' | 'pending'>('pending'),
    resolvedLocation: createAtom<unknown>(null),
    matches: createAtom<unknown[]>([]),
  };
  const stores = {
    status: storeState.status,
    resolvedLocation: storeState.resolvedLocation,
    setMatches: (matches: unknown[]) => storeState.matches.set(matches),
  };
  const batch = useBatch ? jest.fn((callback: () => void) => tanstackStoreBatch(callback)) : undefined;
  router.stores = stores;
  if (batch) {
    router.batch = batch;
  }

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

  return { router, storeState, batch, renderFn, props };
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

  it('hydrates an actual TanStack Router instance through the installed private internals', () => {
    const router = buildActualTanStackRouter();
    // buildActualTanStackRouter always exposes matchRoutes; a missing function
    // would mean an upstream contract break, so assert before use rather than
    // letting `?.` produce a downstream TypeError on `.find()`.
    expect(typeof router.matchRoutes).toBe('function');
    const rawMatches = router.matchRoutes!(router.state.location) as Array<{
      id: string;
      routeId: string;
    }>;
    const productsMatch = rawMatches.find((match) => match.routeId === '/products');
    expect(productsMatch).toBeDefined();
    const dehydratedProductsMatchId = productsMatch?.id.split('/').join('\0');

    const renderFn = createTanStackRouterRenderFunction(
      { createRouter: () => router },
      {
        RouterProvider: ActualRouterProvider as React.ComponentType<{ router: TanStackRouter }>,
        createMemoryHistory: ({ initialEntries }) => createActualMemoryHistory({ initialEntries }),
        createBrowserHistory: () => createActualMemoryHistory({ initialEntries: ['/products'] }),
      },
    );

    const props = {
      __tanstackRouterDehydratedState: {
        url: '/products',
        dehydratedRouter: null,
        ssrRouter: {
          manifest: undefined,
          lastMatchId: dehydratedProductsMatchId,
          matches: [
            {
              i: dehydratedProductsMatchId as string,
              l: { products: ['hammer'] },
              s: 'success',
              ssr: true,
              u: 456,
            },
          ],
        },
      },
    };
    const result = renderFn(props, {
      serverSide: false,
      pathname: '/products',
      search: '',
    } as unknown as RailsContext);

    renderToString(React.createElement(result as React.ComponentType<Record<string, unknown>>, props));

    expect(router.state.status).toBe('idle');
    expect(router.state.resolvedLocation).toEqual(router.state.location);
    expect(router.state.matches).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          id: productsMatch?.id,
          loaderData: { products: ['hammer'] },
          status: 'success',
        }),
      ]),
    );
  });

  it('round-trips actual TanStack Router SSR match data through the public entrypoint', () =>
    withResponsePolyfill(async () => {
      const serverRouter = buildActualTanStackRouter();
      const serverResult = await serverRenderTanStackAppAsync(
        { createRouter: () => serverRouter },
        { initial: 'prop' },
        {
          serverSide: true,
          pathname: '/products',
          search: '',
        } as unknown as RailsContext & { serverSide: true },
        ActualRouterProvider as React.ComponentType<{ router: TanStackRouter }>,
        ({ initialEntries }) => createActualMemoryHistory({ initialEntries }),
      );

      expect(serverResult.dehydratedState.ssrRouter?.matches).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            l: { products: ['hammer'] },
            s: 'success',
          }),
        ]),
      );

      const clientRouter = buildActualTanStackRouter();
      const renderFn = createTanStackRouterRenderFunction(
        { createRouter: () => clientRouter },
        {
          RouterProvider: ActualRouterProvider as React.ComponentType<{ router: TanStackRouter }>,
          createMemoryHistory: ({ initialEntries }) => createActualMemoryHistory({ initialEntries }),
          createBrowserHistory: () => createActualMemoryHistory({ initialEntries: ['/products'] }),
        },
      );

      const props = { __tanstackRouterDehydratedState: serverResult.dehydratedState };
      const result = renderFn(props, {
        serverSide: false,
        pathname: '/products',
        search: '',
      } as unknown as RailsContext);

      renderToString(React.createElement(result as React.ComponentType<Record<string, unknown>>, props));

      expect(clientRouter.state.status).toBe('idle');
      expect(clientRouter.state.matches).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            loaderData: { products: ['hammer'] },
            status: 'success',
          }),
        ]),
      );
    }));

  it('hydrates server-rendered HTML from actual router loader state without recoverable hydration errors', () =>
    withResponsePolyfill(async () => {
      // This narrow provider intentionally reads the first-render router state.
      // Minimal stub: TanStack Router only checks `typeof Response !== 'undefined'` for
      // its SSR helpers. If a future release constructs Response instances, this stub
      // will need to be replaced with a more complete polyfill.
      globalThis.Response = class Response {} as typeof Response;
      // hydration test verifies that SSR-injected state is present before the
      // first client render, which is the hydration contract this adapter owns.
      // Using ActualRouterProvider here exercises TanStack's subscription layer
      // instead and can fail in this package test environment due to nested React.
      const serverRouter = buildActualTanStackRouter();
      const RouterStateProvider = ({ router }: { router: TanStackRouter }) => {
        const productsMatch = router.state.matches.find((match) => {
          const loaderData = (match as { loaderData?: { products?: unknown } }).loaderData;
          return Array.isArray(loaderData?.products);
        }) as { loaderData?: { products?: string[] } } | undefined;
        const products = productsMatch?.loaderData?.products ?? [];

        return React.createElement('main', null, `Products: ${products.join(', ')}`);
      };
      const serverResult = await serverRenderTanStackAppAsync(
        { createRouter: () => serverRouter },
        {},
        {
          serverSide: true,
          pathname: '/products',
          search: '',
        } as unknown as RailsContext & { serverSide: true },
        RouterStateProvider,
        ({ initialEntries }) => createActualMemoryHistory({ initialEntries }),
      );
      const serverHtml = renderToString(serverResult.appElement);
      expect(serverHtml).toContain('Products: hammer');

      const clientRouter = buildActualTanStackRouter();
      const renderFn = createTanStackRouterRenderFunction(
        { createRouter: () => clientRouter },
        {
          RouterProvider: RouterStateProvider,
          createMemoryHistory: ({ initialEntries }) => createActualMemoryHistory({ initialEntries }),
          createBrowserHistory: () => createActualMemoryHistory({ initialEntries: ['/products'] }),
        },
      );
      const props = { __tanstackRouterDehydratedState: serverResult.dehydratedState };
      const clientApp = renderFn(props, {
        serverSide: false,
        pathname: '/products',
        search: '',
      } as unknown as RailsContext);
      const container = document.createElement('div');
      container.innerHTML = serverHtml;
      document.body.appendChild(container);
      const recoverableErrors: unknown[] = [];
      let root: ReturnType<typeof hydrateRoot> | undefined;

      try {
        await compatAct(async () => {
          root = hydrateRoot(
            container,
            React.createElement(clientApp as React.ComponentType<Record<string, unknown>>, props),
            {
              onRecoverableError: (error) => {
                recoverableErrors.push(error);
              },
            },
          );
          await Promise.resolve();
          await Promise.resolve();
        });

        expect(container.textContent).toContain('Products: hammer');
        expect(recoverableErrors).toEqual([]);
      } finally {
        if (root) {
          await compatAct(async () => {
            root?.unmount();
          });
        }
        container.remove();
      }
    }));

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

  it('warns once per render function when RouterClient is provided', () => {
    const warnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});
    const RouterClientA = (_: { router: TanStackRouter }) => React.createElement('div');
    const RouterClientB = (_: { router: TanStackRouter }) => React.createElement('div');

    const createDeps = (routerClient: (p: { router: TanStackRouter }) => React.ReactElement) => ({
      RouterProvider: (_props: { router: TanStackRouter }) => React.createElement('div'),
      RouterClient: routerClient,
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
    });

    const renderFnA = createTanStackRouterRenderFunction(
      { createRouter: () => buildRouter() },
      createDeps(RouterClientA),
    );
    const appA = renderFnA({}, {
      serverSide: false,
      pathname: '/products',
      search: '',
    } as unknown as RailsContext) as (props?: Record<string, unknown>) => React.ReactElement;
    appA({});
    appA({});

    const renderFnB = createTanStackRouterRenderFunction(
      { createRouter: () => buildRouter() },
      createDeps(RouterClientB),
    );
    const appB = renderFnB({}, {
      serverSide: false,
      pathname: '/products',
      search: '',
    } as unknown as RailsContext) as (props?: Record<string, unknown>) => React.ReactElement;
    appB({});

    const deprecationWarnings = warnSpy.mock.calls.filter((call) =>
      String(call[0]).includes('RouterClient parameter is deprecated and ignored'),
    );
    expect(deprecationWarnings).toHaveLength(2);

    warnSpy.mockRestore();
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

  it('injects SSR match data through router.stores when router.__store is unavailable', () => {
    const warnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});
    try {
      const { router, storeState, renderFn, props } = buildStoresHydrationHarness();
      const result = renderFn(props, {
        serverSide: false,
        pathname: '/products',
        search: '',
      } as unknown as RailsContext);

      renderToString(React.createElement(result as React.ComponentType<Record<string, unknown>>, props));

      expect(storeState.status.get()).toBe('idle');
      expect(storeState.resolvedLocation.get()).toBe(router.state.location);
      expect(storeState.matches.get()).toEqual([
        expect.objectContaining({
          id: '/products',
          loaderData: { products: ['hammer'] },
          status: 'success',
        }),
      ]);
      expect(warnSpy).toHaveBeenCalledWith(expect.stringContaining('router.batch is unavailable'));
    } finally {
      warnSpy.mockRestore();
    }
  });

  it('batches router.stores hydration when router.batch is available', () => {
    const { router, storeState, batch, renderFn, props } = buildStoresHydrationHarness({ useBatch: true });
    const result = renderFn(props, {
      serverSide: false,
      pathname: '/products',
      search: '',
    } as unknown as RailsContext);

    renderToString(React.createElement(result as React.ComponentType<Record<string, unknown>>, props));

    expect(batch).toHaveBeenCalledTimes(1);
    expect(storeState.status.get()).toBe('idle');
    expect(storeState.resolvedLocation.get()).toBe(router.state.location);
    expect(storeState.matches.get()).toEqual([
      expect.objectContaining({
        id: '/products',
        loaderData: { products: ['hammer'] },
        status: 'success',
      }),
    ]);
  });

  it('uses legacy __store.setState when both legacy and stores APIs are present', () => {
    const { router, storeState, renderFn, props } = buildStoresHydrationHarness({ includeLegacyStore: true });
    const legacyStore = router.__store;
    const result = renderFn(props, {
      serverSide: false,
      pathname: '/products',
      search: '',
    } as unknown as RailsContext);

    renderToString(React.createElement(result as React.ComponentType<Record<string, unknown>>, props));

    expect(legacyStore?.setState).toHaveBeenCalledTimes(1);
    expect(storeState.status.get()).toBe('pending');
    expect(storeState.resolvedLocation.get()).toBeNull();
    expect(storeState.matches.get()).toEqual([]);
    expect(router.state.matches).toEqual([
      expect.objectContaining({
        id: '/products',
        loaderData: { products: ['hammer'] },
        status: 'success',
      }),
    ]);
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

  it('preloads matched lazy route chunks before the first hydration render', () => {
    const router = buildRouter();
    const rootRoute = { id: '__root__' };
    const productsRoute = { id: '/products' };
    const loadRouteChunk = jest.fn().mockResolvedValue([]);

    (router.matchRoutes as jest.Mock).mockReturnValue([
      { id: '__root__', routeId: '__root__', status: 'pending', updatedAt: 0, loaderData: undefined },
      { id: '/products', routeId: '/products', status: 'pending', updatedAt: 0, loaderData: undefined },
    ]);
    router.looseRoutesById = {
      __root__: rootRoute,
      '/products': productsRoute,
    };
    router.loadRouteChunk = loadRouteChunk;

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

    expect(loadRouteChunk).toHaveBeenCalledTimes(2);
    expect(loadRouteChunk).toHaveBeenNthCalledWith(1, rootRoute);
    expect(loadRouteChunk).toHaveBeenNthCalledWith(2, productsRoute);
  });

  it('throws a clear error when required hydration internals are unavailable', () => {
    const router = buildRouter();
    delete router.matchRoutes;
    delete router.__store;

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
    const props = {
      __tanstackRouterDehydratedState: {
        url: '/products',
        dehydratedRouter: { matches: [{ id: 'products' }] },
      },
    };
    const result = renderFn(props, {
      serverSide: false,
      pathname: '/products',
      search: '',
    } as unknown as RailsContext);

    expect(() =>
      renderToString(React.createElement(result as React.ComponentType<Record<string, unknown>>, props)),
    ).toThrow(
      /router\.matchRoutes\(\) and router\.__store\.setState\(\) or router\.stores\.setMatches\(\) are required/,
    );
  });

  it('runs router.options.hydrate callback with dehydratedData on the SSR hydration path', () => {
    const router = buildRouter();
    const hydrateCallback = jest.fn();
    router.options = {
      hydrate: hydrateCallback,
    };

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
    const dehydratedData = { queryCache: { products: ['hammer'] } };
    const result = renderFn(
      {
        __tanstackRouterDehydratedState: {
          url: '/products?category=tools',
          dehydratedRouter: {
            matches: [{ id: 'products' }],
            dehydratedData,
          },
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
          dehydratedRouter: {
            matches: [{ id: 'products' }],
            dehydratedData,
          },
        },
      }),
    );

    expect(hydrateCallback).toHaveBeenCalledTimes(1);
    expect(hydrateCallback).toHaveBeenCalledWith(dehydratedData);
  });

  it('waits for async router.options.hydrate before triggering post-hydration router.load', async () => {
    const router = buildRouter();
    let resolveHydrate: (() => void) | undefined;
    const hydrateCallback = jest.fn().mockImplementation(
      () =>
        new Promise<void>((resolve) => {
          resolveHydrate = resolve;
        }),
    );
    router.options = { hydrate: hydrateCallback };
    router.load = jest.fn().mockResolvedValue(undefined);

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
        dehydratedRouter: {
          matches: [{ id: 'products' }],
          dehydratedData: { queryCache: { products: ['hammer'] } },
        },
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
      await Promise.resolve();
    });

    expect(hydrateCallback).toHaveBeenCalledTimes(1);
    expect(router.load).not.toHaveBeenCalled();

    await compatAct(async () => {
      resolveHydrate?.();
      await Promise.resolve();
      await Promise.resolve();
    });

    expect(router.load).toHaveBeenCalledTimes(1);

    await compatAct(async () => {
      root.unmount();
    });
  });

  it('does not call router.load when async router.options.hydrate rejects', async () => {
    const router = buildRouter();
    let rejectHydrate: ((reason?: unknown) => void) | undefined;
    const hydrationError = new Error('hydrate failed');
    const hydrateCallback = jest.fn().mockImplementation(
      () =>
        new Promise<void>((_resolve, reject) => {
          rejectHydrate = reject;
        }),
    );
    router.options = { hydrate: hydrateCallback };
    router.load = jest.fn().mockResolvedValue(undefined);
    const errorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});

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
        dehydratedRouter: {
          matches: [{ id: 'products' }],
          dehydratedData: { queryCache: { products: ['hammer'] } },
        },
      },
    };
    const clientApp = renderFn(props, {
      serverSide: false,
      pathname: '/products',
      search: '?category=tools',
    } as unknown as RailsContext);
    const container = document.createElement('div');
    const root = createRoot(container);

    try {
      await compatAct(async () => {
        root.render(React.createElement(clientApp as React.ComponentType<Record<string, unknown>>, props));
        await Promise.resolve();
      });

      expect(hydrateCallback).toHaveBeenCalledTimes(1);
      expect(router.load).not.toHaveBeenCalled();
      expect(router.ssr).toEqual({ manifest: undefined });

      if (!rejectHydrate) {
        throw new Error('Expected router.options.hydrate to be invoked during hydration.');
      }

      await compatAct(async () => {
        rejectHydrate?.(hydrationError);
        await Promise.resolve();
        await Promise.resolve();
      });

      expect(router.load).not.toHaveBeenCalled();
      expect(router.ssr).toBeUndefined();
      expect(errorSpy).toHaveBeenCalledWith(
        'react-on-rails-pro/tanstack-router: Error loading routes after hydration:',
        hydrationError,
      );

      await compatAct(async () => {
        root.unmount();
      });
    } finally {
      errorSpy.mockRestore();
    }
  });

  it('does not call router.load after unmount if async hydration resolves later', async () => {
    const router = buildRouter();
    let resolveHydrate: (() => void) | undefined;
    const hydrateCallback = jest.fn().mockImplementation(
      () =>
        new Promise<void>((resolve) => {
          resolveHydrate = resolve;
        }),
    );
    router.options = { hydrate: hydrateCallback };
    router.load = jest.fn().mockResolvedValue(undefined);

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
        dehydratedRouter: {
          matches: [{ id: 'products' }],
          dehydratedData: { queryCache: { products: ['hammer'] } },
        },
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
      await Promise.resolve();
    });

    expect(hydrateCallback).toHaveBeenCalledTimes(1);
    expect(router.load).not.toHaveBeenCalled();

    await compatAct(async () => {
      root.unmount();
    });

    if (!resolveHydrate) {
      throw new Error('Expected router.options.hydrate to be invoked during hydration.');
    }

    await compatAct(async () => {
      resolveHydrate?.();
      await Promise.resolve();
      await Promise.resolve();
    });

    expect(router.load).not.toHaveBeenCalled();
  });

  it('initializes hydration store injection once per created router in StrictMode', async () => {
    const setStateCalls: jest.Mock[] = [];
    const options = {
      createRouter: jest.fn().mockImplementation(() => {
        const router = buildRouter();
        const setState = jest.fn();
        router.__store = { setState };
        setStateCalls.push(setState);
        return router;
      }),
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
      root.render(
        React.createElement(
          React.StrictMode,
          null,
          React.createElement(clientApp as React.ComponentType<Record<string, unknown>>, props),
        ),
      );
      await Promise.resolve();
    });

    expect(setStateCalls.length).toBeGreaterThan(0);
    setStateCalls.forEach((setState) => {
      expect(setState).toHaveBeenCalledTimes(1);
    });

    await compatAct(async () => {
      root.unmount();
    });
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

  it('clears router.ssr in cleanup when post-hydration load does not settle', async () => {
    const router = buildRouter();
    router.load = jest.fn().mockImplementation(() => new Promise<void>(() => {}));
    const cancelLoad = jest.fn();
    (router as TanStackRouter & { cancelLoad?: () => void }).cancelLoad = cancelLoad;

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

    expect(router.ssr).toEqual({ manifest: undefined });

    await compatAct(async () => {
      root.unmount();
      await Promise.resolve();
    });

    expect(router.ssr).toBeUndefined();
    expect(cancelLoad).toHaveBeenCalledTimes(1);
  });

  it('warns if the temporary router.ssr flag is cleared before the post-hydration effect', async () => {
    const router = buildRouter();
    router.options = { hydrate: undefined };
    const originalNodeEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'development';
    const warnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});

    const options = {
      createRouter: () => router,
    };
    const deps = {
      RouterProvider: ({ router: providerRouter }: { router: TanStackRouter }) => {
        // Intentional render-phase mutation for test isolation: simulate TanStack
        // Router clearing the private flag before our post-hydration effect.
        providerRouter.ssr = undefined;
        return React.createElement('div');
      },
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

    try {
      await compatAct(async () => {
        root.render(React.createElement(clientApp as React.ComponentType<Record<string, unknown>>, props));
        await Promise.resolve();
      });

      expect(warnSpy).toHaveBeenCalledWith(
        'react-on-rails-pro/tanstack-router: router.ssr was unexpectedly ' +
          'cleared between render-phase init and the post-hydration effect. ' +
          'TanStack Router\'s private "ssr" API may have changed — verify ' +
          '@tanstack/react-router is within the supported range ' +
          '(>=1.139.0 <2.0.0).',
      );
    } finally {
      process.env.NODE_ENV = originalNodeEnv;
      warnSpy.mockRestore();
      await compatAct(() => {
        root.unmount();
      });
    }
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

  it('waits for the matched route chunk preload promise before triggering post-hydration router.load', async () => {
    // Regression test for the Suspense-gate removal: with the gate gone,
    // RouterProvider renders directly during hydration. The chunk-preload
    // behavior must still be preserved by awaiting routeChunkPreloadPromiseRef
    // inside runPostHydrationLoad before calling router.load(); otherwise
    // post-hydration navigation could race ahead of matched lazy chunks.
    const router = buildRouter();
    const productsRoute = { id: '/products' };
    let resolveChunk: (() => void) | undefined;
    const loadRouteChunk = jest.fn().mockImplementation(
      () =>
        new Promise<void>((resolve) => {
          resolveChunk = resolve;
        }),
    );
    (router.matchRoutes as jest.Mock).mockReturnValue([
      { id: '/products', routeId: '/products', status: 'pending', updatedAt: 0, loaderData: undefined },
    ]);
    router.looseRoutesById = { '/products': productsRoute };
    router.loadRouteChunk = loadRouteChunk;
    // No user-defined hydrate callback — isolate the chunk-preload await path.
    router.options = { hydrate: undefined };

    const renderFn = createTanStackRouterRenderFunction(
      { createRouter: () => router },
      {
        RouterProvider: (_: { router: TanStackRouter }) => React.createElement('div'),
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
      },
    };
    const clientApp = renderFn(props, {
      serverSide: false,
      pathname: '/products',
      search: '?category=tools',
    } as unknown as RailsContext);
    const container = document.createElement('div');
    const root = createRoot(container);

    try {
      await compatAct(async () => {
        root.render(React.createElement(clientApp as React.ComponentType<Record<string, unknown>>, props));
        await Promise.resolve();
      });

      // Chunk preload kicked off during render-phase init, but the post-hydration
      // load must remain blocked until the preload promise settles.
      expect(loadRouteChunk).toHaveBeenCalledTimes(1);
      expect(loadRouteChunk).toHaveBeenCalledWith(productsRoute);
      expect(router.load).not.toHaveBeenCalled();

      if (!resolveChunk) {
        throw new Error('Expected loadRouteChunk to be invoked during render-phase init.');
      }
      const settleChunk = resolveChunk;

      await compatAct(async () => {
        settleChunk();
        // Use a macrotask boundary so all queued microtasks (the preload
        // promise's .then plus every await hop in runPostHydrationLoad) fully
        // drain before we assert. Counting individual ticks is fragile:
        // adding or removing a single await in runPostHydrationLoad would
        // silently break the assertion below.
        await new Promise((r) => {
          setTimeout(r, 0);
        });
      });

      expect(router.load).toHaveBeenCalledTimes(1);
    } finally {
      resolveChunk?.();
      await compatAct(() => {
        root.unmount();
      });
    }
  });

  it('continues post-hydration router.load after matched route chunk preload rejects', async () => {
    const router = buildRouter();
    const productsRoute = { id: '/products' };
    let resolveChunk: (() => void) | undefined;
    let rejectChunk: ((reason?: unknown) => void) | undefined;
    const chunkError = new Error('chunk failed');
    const loadRouteChunk = jest.fn().mockImplementation(
      () =>
        new Promise<void>((resolve, reject) => {
          resolveChunk = resolve;
          rejectChunk = reject;
        }),
    );
    (router.matchRoutes as jest.Mock).mockReturnValue([
      { id: '/products', routeId: '/products', status: 'pending', updatedAt: 0, loaderData: undefined },
    ]);
    router.looseRoutesById = { '/products': productsRoute };
    router.loadRouteChunk = loadRouteChunk;
    router.options = { hydrate: undefined };
    const errorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});

    const renderFn = createTanStackRouterRenderFunction(
      { createRouter: () => router },
      {
        RouterProvider: (_: { router: TanStackRouter }) => React.createElement('div'),
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
      },
    };
    const clientApp = renderFn(props, {
      serverSide: false,
      pathname: '/products',
      search: '?category=tools',
    } as unknown as RailsContext);
    const container = document.createElement('div');
    const root = createRoot(container);

    try {
      await compatAct(async () => {
        root.render(React.createElement(clientApp as React.ComponentType<Record<string, unknown>>, props));
        await Promise.resolve();
      });

      expect(loadRouteChunk).toHaveBeenCalledTimes(1);
      expect(loadRouteChunk).toHaveBeenCalledWith(productsRoute);
      expect(router.load).not.toHaveBeenCalled();

      if (!rejectChunk) {
        throw new Error('Expected loadRouteChunk to be invoked during render-phase init.');
      }
      const rejectLoadedChunk = rejectChunk;

      await compatAct(async () => {
        rejectLoadedChunk(chunkError);
        await new Promise((r) => {
          setTimeout(r, 0);
        });
      });

      expect(errorSpy).toHaveBeenCalledWith(
        'react-on-rails-pro/tanstack-router: Error preloading matched route chunks:',
        chunkError,
      );
      expect(router.load).toHaveBeenCalledTimes(1);
    } finally {
      resolveChunk?.();
      errorSpy.mockRestore();
      await compatAct(() => {
        root.unmount();
      });
    }
  });

  it('does not double-call loadRouteChunk when StrictMode replays hydration effects', async () => {
    const router = buildRouter();
    const productsRoute = { id: '/products' };
    const resolveChunks: Array<() => void> = [];
    const loadRouteChunk = jest.fn().mockImplementation(
      () =>
        new Promise<void>((resolve) => {
          resolveChunks.push(resolve);
        }),
    );
    (router.matchRoutes as jest.Mock).mockReturnValue([
      { id: '/products', routeId: '/products', status: 'pending', updatedAt: 0, loaderData: undefined },
    ]);
    router.looseRoutesById = { '/products': productsRoute };
    router.loadRouteChunk = loadRouteChunk;
    router.options = { hydrate: undefined };

    const renderFn = createTanStackRouterRenderFunction(
      { createRouter: () => router },
      {
        RouterProvider: (_: { router: TanStackRouter }) => React.createElement('div'),
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
      },
    };
    const Client = renderFn(props, {
      serverSide: false,
      pathname: '/products',
      search: '?category=tools',
    } as unknown as RailsContext) as React.ComponentType<Record<string, unknown>>;
    const container = document.createElement('div');
    const root = createRoot(container);

    await compatAct(async () => {
      root.render(React.createElement(React.StrictMode, null, React.createElement(Client, props)));
      await Promise.resolve();
    });

    // Render-phase init runs once per RouterProvider mount and is guarded by
    // routerRef so a discarded StrictMode render does not kick off an extra
    // preload. Pinning the count catches a future regression where the
    // preload fires unexpectedly often.
    expect(loadRouteChunk).toHaveBeenCalledTimes(1);
    expect(loadRouteChunk).toHaveBeenCalledWith(productsRoute);
    expect(router.load).not.toHaveBeenCalled();
    expect(router.ssr).toEqual({ manifest: undefined });

    await compatAct(async () => {
      expect(resolveChunks).toHaveLength(1);
      resolveChunks.forEach((resolve) => resolve());
      await new Promise((r) => {
        setTimeout(r, 0);
      });
    });

    expect(router.load).toHaveBeenCalledTimes(1);
    expect(router.ssr).toBeUndefined();

    await compatAct(async () => {
      root.unmount();
    });
  });

  it('does not warn about cleared router.ssr after full remount of a cached router', async () => {
    // Regression test for the WeakMap cache: after a full unmount+remount of
    // the same router instance, the cached didSetSsrFlag must reflect the
    // post-hydration clear — otherwise the dev sanity-check below at
    // clientHydrate.ts:361 would falsely warn that router.ssr "was unexpectedly
    // cleared" on the second mount even though we cleared it correctly.
    const router = buildRouter();
    const productsRoute = { id: '/products' };
    const loadRouteChunk = jest.fn().mockResolvedValue(undefined);
    (router.matchRoutes as jest.Mock).mockReturnValue([
      { id: '/products', routeId: '/products', status: 'pending', updatedAt: 0, loaderData: undefined },
    ]);
    router.looseRoutesById = { '/products': productsRoute };
    router.loadRouteChunk = loadRouteChunk;
    router.options = { hydrate: undefined };

    const originalNodeEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'development';
    const warnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});

    const renderFn = createTanStackRouterRenderFunction(
      { createRouter: () => router },
      {
        RouterProvider: (_: { router: TanStackRouter }) => React.createElement('div'),
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
      },
    };
    const Client = renderFn(props, {
      serverSide: false,
      pathname: '/products',
      search: '?category=tools',
    } as unknown as RailsContext) as React.ComponentType<Record<string, unknown>>;

    try {
      // First mount: render-phase init runs, post-hydration effect clears router.ssr.
      const container1 = document.createElement('div');
      const root1 = createRoot(container1);
      await compatAct(async () => {
        root1.render(React.createElement(Client, props));
        await new Promise((r) => {
          setTimeout(r, 0);
        });
      });
      expect(router.ssr).toBeUndefined();
      await compatAct(async () => {
        root1.unmount();
      });

      // Second mount of the same cached router. The render-phase guard hits
      // the WeakMap and restores didSetSsrFlag from the cache. If the cache
      // had been left stale at didSetSsrFlag=true, the dev sanity check would
      // fire here because router.ssr is already null on the cached router.
      warnSpy.mockClear();
      const container2 = document.createElement('div');
      const root2 = createRoot(container2);
      await compatAct(async () => {
        root2.render(React.createElement(Client, props));
        await new Promise((r) => {
          setTimeout(r, 0);
        });
      });

      expect(warnSpy).not.toHaveBeenCalledWith(
        expect.stringContaining('router.ssr was unexpectedly cleared'),
      );

      await compatAct(async () => {
        root2.unmount();
      });
    } finally {
      process.env.NODE_ENV = originalNodeEnv;
      warnSpy.mockRestore();
    }
  });

  it('renders RouterProvider directly without an enclosing Suspense boundary during hydration', () => {
    // Regression test for the Suspense-gate removal: both the server tree
    // (serverRender.ts's `buildAppElement`) and the client hydration tree
    // emit AppWrapper > RouterProvider with no Suspense wrapper. A Suspense
    // wrapper on either side would emit `<!--$-->`/`<!--/$-->` markers in
    // the server HTML and require a matching boundary on the client; an
    // asymmetric boundary causes a hydration mismatch and React bails to a
    // full client-side re-render.
    const router = buildRouter();
    const renderFn = createTanStackRouterRenderFunction(
      { createRouter: () => router },
      {
        RouterProvider: (_: { router: TanStackRouter }) =>
          React.createElement('div', { 'data-testid': 'provider' }),
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
    const Client = renderFn(props, {
      serverSide: false,
      pathname: '/products',
      search: '?category=tools',
    } as unknown as RailsContext) as React.ComponentType<Record<string, unknown>>;

    // The fix's strongest guarantee: the rendered HTML must be exactly the
    // mock RouterProvider's output. With a Suspense wrapper (the bug),
    // react-dom/server emits <!--$-->/<!--/$--> markers around the children
    // even when the boundary does not actually suspend, so this equality
    // assertion catches any wrapping Suspense boundary.
    const html = renderToString(React.createElement(Client, props));
    expect(html).toBe('<div data-testid="provider"></div>');
  });

  it('throws if RouterProvider suspends during server render', async () => {
    const router = buildRouter();

    const result = await serverRenderTanStackAppAsync(
      { createRouter: () => router },
      { initial: 'prop' },
      {
        serverSide: true,
        pathname: '/products',
        search: '',
      } as unknown as RailsContext & { serverSide: true },
      (_props: { router: TanStackRouter }) => {
        throw Promise.resolve();
      },
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

    // React's legacy `renderToString` produces its own "component suspended
    // while responding to synchronous input" error when RouterProvider
    // suspends during SSR. The server tree no longer wraps RouterProvider in
    // <Suspense> (doing so would break hydration parity in React 19), so the
    // built-in React error is the loud throw we rely on here.
    expect(() => renderToString(result.appElement)).toThrow(/component suspended/);
  });
});
