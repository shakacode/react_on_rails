import * as React from 'react';
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
    matches: [] as unknown[],
  };

  return {
    update: jest.fn(),
    load: jest.fn().mockResolvedValue(undefined),
    state,
    dehydrate: jest.fn().mockReturnValue({ matches: [{ id: 'products' }] }),
    hydrate: jest.fn(),
  };
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

    const resolved = await result as ServerRenderResult;
    expect(renderFn.renderFunction).toBe(true);
    expect(React.isValidElement(resolved.renderedHtml)).toBe(true);
    expect(resolved.clientProps).toEqual({
      __tanstackRouterDehydratedState: {
        url: '/products?category=tools',
        dehydratedRouter: { matches: [{ id: 'products' }] },
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

  it('enables SSR mode for async server rendering before returning dehydrated state', async () => {
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
    expect(router.ssr).toBe(true);
    expect(result.dehydratedState).toEqual({
      url: '/products?category=tools',
      dehydratedRouter: { matches: [{ id: 'products' }] },
    });
  });
});
