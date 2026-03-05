import * as React from 'react';
import { renderToString } from 'react-dom/server';
import { createTanStackRouterRenderFunction } from '../src/tanstack-router/index.ts';
import type { RailsContext, ServerRenderResult } from '../src/types/index.ts';
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
    matchRoutes: jest.fn().mockReturnValue([{ id: 'products' }]),
    state,
    dehydrate: jest.fn().mockReturnValue({ matches: [{ id: 'products' }] }),
    __store: {
      setState: jest.fn((updater) => {
        Object.assign(state, updater(state as unknown as Record<string, unknown>));
      }),
    },
  };
}

describe('tanstack-router integration', () => {
  it('returns serverRenderHash with dehydrated state in clientProps', () => {
    const router = buildRouter();
    const options = {
      createRouter: () => router,
    };
    const deps = {
      RouterProvider: ({ children }: { children?: React.ReactNode }) =>
        React.createElement('div', null, children),
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
    } as unknown as RailsContext) as ServerRenderResult;

    expect(renderFn.renderFunction).toBe(true);
    expect(React.isValidElement(result.renderedHtml)).toBe(true);
    expect(result.clientProps).toEqual({
      __tanstackRouterDehydratedState: {
        url: '/products?category=tools',
        dehydratedRouter: { matches: [{ id: 'products' }] },
      },
    });
    expect(deps.createMemoryHistory).toHaveBeenCalledWith({ initialEntries: ['/products?category=tools'] });
  });

  it('normalizes railsContext.search when it does not include a leading "?"', () => {
    const router = buildRouter();
    const options = {
      createRouter: () => router,
    };
    const deps = {
      RouterProvider: ({ children }: { children?: React.ReactNode }) =>
        React.createElement('div', null, children),
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
    renderFn({ initial: 'prop' }, {
      serverSide: true,
      pathname: '/products',
      search: 'category=tools',
    } as unknown as RailsContext);

    expect(deps.createMemoryHistory).toHaveBeenCalledWith({ initialEntries: ['/products?category=tools'] });
  });

  it('returns a client React element on client-side render', () => {
    const options = {
      createRouter: () => buildRouter(),
    };
    const deps = {
      RouterProvider: ({ children }: { children?: React.ReactNode }) =>
        React.createElement('div', null, children),
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

    expect(React.isValidElement(result)).toBe(true);
  });

  it('hydrates with railsContext path when dehydration payload exists without dehydrated router', () => {
    const router = buildRouter();
    const options = {
      createRouter: () => router,
    };
    const deps = {
      RouterProvider: ({ children }: { children?: React.ReactNode }) =>
        React.createElement('div', null, children),
      createMemoryHistory: jest.fn(),
      createBrowserHistory: jest.fn().mockReturnValue({
        location: {
          pathname: '/wrong-path',
          search: '?wrong=1',
          hash: '',
          href: '/wrong-path?wrong=1',
          state: null,
        },
      }),
    };

    const renderFn = createTanStackRouterRenderFunction(options, deps);
    const result = renderFn(
      {
        __tanstackRouterDehydratedState: {
          url: '/products?category=tools',
          dehydratedRouter: null,
        },
      },
      {
        serverSide: false,
        pathname: '/products',
        search: '?category=tools',
      } as unknown as RailsContext,
    );

    expect(React.isValidElement(result)).toBe(true);
    renderToString(result as React.ReactElement);

    expect(router.matchRoutes).toHaveBeenCalledWith('/products', '?category=tools');
    expect((router as { ssr?: boolean }).ssr).toBe(true);
  });

  it('does not pass __tanstackRouterDehydratedState through AppWrapper props', () => {
    const router = buildRouter();
    const observedProps: Array<Record<string, unknown>> = [];
    const options = {
      createRouter: () => router,
      AppWrapper: ({ children, ...rest }: { children: React.ReactNode } & Record<string, unknown>) => {
        observedProps.push(rest);
        return React.createElement('section', null, children);
      },
    };
    const deps = {
      RouterProvider: ({ children }: { children?: React.ReactNode }) =>
        React.createElement('div', null, children),
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
          dehydratedRouter: null,
        },
        userId: 42,
      },
      {
        serverSide: false,
        pathname: '/products',
        search: '?category=tools',
      } as unknown as RailsContext,
    );

    renderToString(result as React.ReactElement);

    expect(observedProps).toHaveLength(1);
    expect(observedProps[0]).toEqual({ userId: 42 });
  });
});
