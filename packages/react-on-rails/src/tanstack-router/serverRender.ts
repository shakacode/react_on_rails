import { createElement, type ReactElement } from 'react';
import type { TanStackRouter, TanStackRouterOptions, DehydratedRouterState } from './types.ts';
import type { RailsContext } from '../types/index.ts';

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
        'or file an issue at https://github.com/shakacode/react_on_rails/issues',
    );
  }

  if (typeof router.matchRoutes !== 'function') {
    throw new Error(
      'react-on-rails/tanstack-router: Expected router.matchRoutes to be a function. ' +
        'Please check that your @tanstack/react-router version is compatible.',
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
 * Pinned behavior from @tanstack/react-router@1.139.0
 */
function injectRouteMatchesSync(router: TanStackRouter): void {
  const matches = router.matchRoutes(router.state.location.pathname, router.state.location.search);

  router.__store.setState((s: Record<string, unknown>) => ({
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
  extraProps: Record<string, unknown>,
): ReactElement {
  let app: ReactElement = createElement(RouterProvider, { router });
  if (AppWrapper) {
    app = createElement(AppWrapper, { ...extraProps, children: app } as any);
  }
  return app;
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
): ReactElement {
  const router = options.createRouter();
  const url = railsContext.pathname + (railsContext.search || '');

  // Set memory history for server-side rendering
  const memoryHistory = createMemoryHistory({ initialEntries: [url] });
  router.update({ history: memoryHistory });

  // Validate internal APIs before using them
  validateRouterInternals(router);

  // WORKAROUND: Synchronously populate route matches.
  // TanStack Router's router.load() is async, but renderToString is sync.
  // This injects the matched routes directly into the internal store.
  injectRouteMatchesSync(router);

  // WORKAROUND: Set SSR flag to prevent Suspense boundary issues.
  // This causes TanStack Router to use SafeFragment instead of React.Suspense,
  // which avoids hydration mismatches.
  (router as any).ssr = true;

  // Build the dehydrated state to pass to the client
  const dehydratedState: DehydratedRouterState = {
    url,
    dehydratedRouter: typeof router.dehydrate === 'function' ? router.dehydrate() : null,
  };

  // Inject dehydrated state into props so it's available on the client.
  // React on Rails serializes props as JSON in a <script> tag, so the client
  // render function will receive these additional props.
  const propsWithState = {
    ...props,
    __tanstackRouterDehydratedState: dehydratedState,
  };

  // Return as ReactElement — serverRenderReactComponent will call renderToString on it.
  return buildAppElement(router, RouterProvider, options.AppWrapper, propsWithState);
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
): Promise<ReactElement> {
  const router = options.createRouter();
  const url = railsContext.pathname + (railsContext.search || '');

  const memoryHistory = createMemoryHistory({ initialEntries: [url] });
  router.update({ history: memoryHistory });

  // Use the public API — await route loading
  await router.load();

  const dehydratedState: DehydratedRouterState = {
    url,
    dehydratedRouter: typeof router.dehydrate === 'function' ? router.dehydrate() : null,
  };

  const propsWithState = {
    ...props,
    __tanstackRouterDehydratedState: dehydratedState,
  };

  return buildAppElement(router, RouterProvider, options.AppWrapper, propsWithState);
}
