import { createElement, type ReactElement } from 'react';
import type { TanStackRouter, TanStackRouterOptions, DehydratedRouterState } from './types.ts';
import type { RailsContext } from '../types/index.ts';
import { normalizeSearch, locationSearch } from './utils.ts';

/* eslint-disable @typescript-eslint/no-explicit-any, @typescript-eslint/no-unsafe-argument, @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access, no-underscore-dangle */

/**
 * Validates that the TanStack Router internal APIs we depend on are present.
 * Throws a clear error if the router version has changed its internals.
 */
function validateRouterInternals(router: TanStackRouter): void {
  if (typeof router.__store?.setState !== 'function') {
    throw new Error(
      'react-on-rails/tanstack-router: TanStack Router internal API changed. ' +
        'Expected router.__store.setState to be a function. ' +
        'Please check that your @tanstack/react-router version is compatible, ' +
        'or file an issue at https://github.com/shakacode/react_on_rails/issues. ' +
        'Supported @tanstack/react-router range: >=1.0.0 <2.0.0.',
    );
  }

  if (typeof router.matchRoutes !== 'function') {
    throw new Error(
      'react-on-rails/tanstack-router: Expected router.matchRoutes to be a function. ' +
        'Please check that your @tanstack/react-router version is compatible. ' +
        'Supported range: >=1.0.0 <2.0.0.',
    );
  }

  const pathname = router.state?.location?.pathname;
  if (typeof pathname !== 'string') {
    throw new Error(
      'react-on-rails/tanstack-router: validateRouterInternals expected router.state.location.pathname to be a string. ' +
        'Please check that your @tanstack/react-router version is compatible. ' +
        'Supported range: >=1.0.0 <2.0.0.',
    );
  }

  const hasSearch =
    Object.prototype.hasOwnProperty.call(router.state.location, 'search') ||
    Object.prototype.hasOwnProperty.call(router.state.location, 'searchStr');
  if (!hasSearch) {
    throw new Error(
      'react-on-rails/tanstack-router: validateRouterInternals expected router.state.location.search (or searchStr) to exist. ' +
        'Please check that your @tanstack/react-router version is compatible. ' +
        'Supported range: >=1.0.0 <2.0.0.',
    );
  }
}

/**
 * Synchronously injects route matches into the router's internal store.
 *
 * This workaround is necessary because:
 * - TanStack Router's router.load() is async
 * - React's renderToString() is synchronous
 * - Without pre-populated matches, SSR output would be empty
 *
 * Uses private API: router.__store.setState()
 * Verified against @tanstack/react-router@1.163.3 within the supported range >=1.0.0 <2.0.0.
 */
function injectRouteMatchesSync(router: TanStackRouter, fallbackUrl: string): void {
  const store = router.__store;
  if (!store) {
    return;
  }

  const parsedUrl = new URL(fallbackUrl, 'https://react-on-rails.local');
  const { location } = router.state;
  const pathname = typeof location.pathname === 'string' ? location.pathname : parsedUrl.pathname;
  const search = locationSearch(location) || parsedUrl.search;
  const matches = router.matchRoutes(pathname, search);

  store.setState((s: Record<string, unknown>) => ({
    ...s,
    status: 'idle',
    resolvedLocation: (s as { location: unknown }).location,
    matches,
  }));
}

/**
 * Builds a React element tree with RouterProvider and optional AppWrapper.
 */
function buildAppElement(
  router: TanStackRouter,
  RouterProvider: React.ComponentType<any>,
  AppWrapper: TanStackRouterOptions['AppWrapper'],
  wrapperProps: Record<string, unknown>,
): ReactElement {
  let app: ReactElement = createElement(RouterProvider, { router });
  if (AppWrapper) {
    app = createElement(AppWrapper, { ...wrapperProps, children: app } as any);
  }
  return app;
}

export interface TanStackServerRenderResult {
  appElement: ReactElement;
  dehydratedState: DehydratedRouterState;
}

/**
 * Server-side render a TanStack Router app synchronously.
 *
 * Flow:
 * 1. Create router with memory history from the request URL
 * 2. Synchronously inject route matches (private API workaround)
 * 3. Set router.ssr = true to prevent Suspense issues
 * 4. Return a React element for renderToString
 */
export function serverRenderTanStackApp(
  options: TanStackRouterOptions,
  props: Record<string, unknown>,
  railsContext: RailsContext & { serverSide: true },
  RouterProvider: React.ComponentType<any>,
  createMemoryHistory: (opts: { initialEntries: string[] }) => any,
): TanStackServerRenderResult {
  const router = options.createRouter();
  const url = railsContext.pathname + normalizeSearch(railsContext.search);

  // Set memory history for server-side rendering
  const memoryHistory = createMemoryHistory({ initialEntries: [url] });
  router.update({ history: memoryHistory });

  // Validate internal APIs before using them
  validateRouterInternals(router);

  // WORKAROUND: Synchronously populate route matches.
  // TanStack Router's router.load() is async, but renderToString is sync.
  // This injects the matched routes directly into the internal store.
  injectRouteMatchesSync(router, url);

  // WORKAROUND: Set SSR flag to prevent Suspense boundary issues.
  // This causes TanStack Router to use SafeFragment instead of React.Suspense,
  // which avoids hydration mismatches.
  (router as any).ssr = true;

  // Build the dehydrated state to pass to the client
  const dehydratedState: DehydratedRouterState = {
    url,
    dehydratedRouter: typeof router.dehydrate === 'function' ? router.dehydrate() : null,
  };

  return {
    appElement: buildAppElement(router, RouterProvider, options.AppWrapper, props),
    dehydratedState,
  };
}

/**
 * Async server-side render for use with React on Rails Pro NodeRenderer.
 * Uses the public router.load() API — no private API workarounds needed.
 *
 * Requires: rendering_returns_promises = true in React on Rails Pro config.
 */
export async function serverRenderTanStackAppAsync(
  options: TanStackRouterOptions,
  props: Record<string, unknown>,
  railsContext: RailsContext & { serverSide: true },
  RouterProvider: React.ComponentType<any>,
  createMemoryHistory: (opts: { initialEntries: string[] }) => any,
): Promise<TanStackServerRenderResult> {
  const router = options.createRouter();
  const url = railsContext.pathname + normalizeSearch(railsContext.search);

  const memoryHistory = createMemoryHistory({ initialEntries: [url] });
  router.update({ history: memoryHistory });

  // Use the public API — await route loading
  await router.load();

  // Keep server markup consistent with the synchronous render path.
  (router as any).ssr = true;

  const dehydratedState: DehydratedRouterState = {
    url,
    dehydratedRouter: typeof router.dehydrate === 'function' ? router.dehydrate() : null,
  };

  return {
    appElement: buildAppElement(router, RouterProvider, options.AppWrapper, props),
    dehydratedState,
  };
}
