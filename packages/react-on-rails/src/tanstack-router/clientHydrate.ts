import { createElement, useEffect, useRef, type ReactElement } from 'react';
import type { TanStackRouter, TanStackRouterOptions, DehydratedRouterState } from './types.ts';
import type { RailsContext } from '../types/index.ts';

/* eslint-disable @typescript-eslint/no-explicit-any, @typescript-eslint/no-unsafe-argument, @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access, no-underscore-dangle, import/prefer-default-export */

/**
 * Client-side hydration for a TanStack Router app.
 *
 * Flow:
 * 1. Create router with browser history
 * 2. Synchronously inject route matches (same as server) to prevent hydration mismatch
 * 3. Set router.ssr = true to skip auto-load on mount (Transitioner behavior)
 * 4. After hydration, trigger router.load() to enable client-side navigation
 * 5. Return a React component that renders RouterProvider
 */
export function clientHydrateTanStackApp(
  options: TanStackRouterOptions,
  props: Record<string, unknown>,
  _railsContext: RailsContext & { serverSide: false },
  RouterProvider: React.ComponentType<any>,
  createBrowserHistory: () => any,
): ReactElement {
  const dehydratedState = props.__tanstackRouterDehydratedState as DehydratedRouterState | undefined;

  // Create the app component that manages router lifecycle
  const AppComponent = () => {
    const routerRef = useRef<TanStackRouter | null>(null);

    if (routerRef.current === null) {
      const router = options.createRouter();

      // Set browser history for client-side navigation
      const browserHistory = createBrowserHistory();
      router.update({ history: browserHistory });

      // Synchronously inject route matches to match server output.
      // This prevents hydration mismatches by ensuring the client renders
      // the same route tree as the server.
      if (typeof router.matchRoutes === 'function' && router.__store?.setState) {
        const matches = router.matchRoutes(router.state.location.pathname, router.state.location.search);
        router.__store.setState((s: Record<string, unknown>) => ({
          ...s,
          status: 'idle',
          resolvedLocation: (s as { location: unknown }).location,
          matches,
        }));
      }

      // Set SSR flag to prevent Transitioner from auto-calling router.load() on mount.
      // This avoids refetching data that was already loaded during SSR.
      (router as any).ssr = true;

      // Hydrate router with dehydrated state from server
      if (dehydratedState?.dehydratedRouter && typeof router.hydrate === 'function') {
        router.hydrate(dehydratedState.dehydratedRouter);
      }

      routerRef.current = router;
    }

    const router = routerRef.current;

    // After mount, trigger router.load() to enable client-side navigation.
    // The SSR flag prevented auto-loading, so we do it manually here.
    const isFirstRender = useRef(true);
    useEffect(() => {
      if (isFirstRender.current) {
        isFirstRender.current = false;

        // If the router isn't fully loaded yet, trigger loading
        if (router.state.status !== 'idle') {
          router.load().catch((err: unknown) => {
            console.error('react-on-rails/tanstack-router: Error loading routes after hydration:', err);
          });
        }
      }
    }, []); // eslint-disable-line react-hooks/exhaustive-deps -- router is a ref, intentionally stable

    let app: ReactElement = createElement(RouterProvider, { router });
    if (options.AppWrapper) {
      app = createElement(options.AppWrapper, { ...props, children: app } as any);
    }

    return app;
  };

  return createElement(AppComponent);
}
