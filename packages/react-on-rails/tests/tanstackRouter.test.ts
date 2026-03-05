import * as React from 'react';
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
});
