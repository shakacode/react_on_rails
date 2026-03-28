import * as React from 'react';
import { createRoot } from 'react-dom/client';
import { act } from 'react-dom/test-utils';
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
    state,
    dehydrate: jest.fn().mockReturnValue({ matches: [{ id: 'products' }] }),
    hydrate: jest.fn(),
  };
}

type ActCallback = () => void | Promise<void>;

async function compatAct(callback: ActCallback): Promise<void> {
  const reactAct = (React as typeof React & { act?: (cb: ActCallback) => Promise<unknown> | unknown }).act;
  if (typeof reactAct === 'function') {
    await reactAct(callback);
    return;
  }

  const { act } = await import('react-dom/test-utils');
  await act(callback);
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
