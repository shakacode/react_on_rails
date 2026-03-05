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
function normalizeSearch(search: string | null | undefined): string {
  if (!search) {
    return '';
  }

  return search.startsWith('?') ? search : `?${search}`;
}

export function clientHydrateTanStackApp(
  options: TanStackRouterOptions,
  props: Record<string, unknown>,
  railsContext: RailsContext & { serverSide: false },
  RouterProvider: React.ComponentType<any>,
  createBrowserHistory: () => any,
): ReactElement {
  const dehydratedState = props.__tanstackRouterDehydratedState as DehydratedRouterState | undefined;
  const hasSsrPayload = dehydratedState !== undefined;
  const hasDehydratedRouter =
    dehydratedState?.dehydratedRouter !== undefined && dehydratedState.dehydratedRouter !== null;

  // Create the app component that manages router lifecycle
  const AppComponent = () => {
    const routerRef = useRef<TanStackRouter | null>(null);

    if (routerRef.current === null) {
      const router = options.createRouter();

      // Set browser history for client-side navigation
      const browserHistory = createBrowserHistory();
      router.update({ history: browserHistory });

      // Hydrate router with dehydrated state from server if available.
      if (hasDehydratedRouter && typeof router.hydrate === 'function') {
        router.hydrate(dehydratedState.dehydratedRouter);
      } else if (typeof router.matchRoutes === 'function' && router.__store?.setState) {
        // Fall back to injecting route matches when no dehydrated state is available.
        // This keeps the initial client route tree aligned with SSR output.
        const routerLocation = router.state?.location as { pathname?: string; search?: string } | undefined;
        const pathname =
          railsContext.pathname ||
          (browserHistory.location as { pathname?: string } | undefined)?.pathname ||
          routerLocation?.pathname ||
          '/';
        const searchFromRouter =
          typeof routerLocation?.search === 'string' ? routerLocation.search : undefined;
        const search =
          normalizeSearch(railsContext.search) ||
          normalizeSearch((browserHistory.location as { search?: string } | undefined)?.search) ||
          normalizeSearch(searchFromRouter);
        const matches = router.matchRoutes(pathname, search);
        router.__store.setState((s: Record<string, unknown>) => ({
          ...s,
          status: 'idle',
          resolvedLocation: (s as { location: unknown }).location,
          matches,
        }));
      } else if (hasSsrPayload) {
        throw new Error(
          'react-on-rails/tanstack-router: Cannot hydrate SSR payload because required TanStack Router internals ' +
            'are unavailable (expected router.matchRoutes and router.__store.setState). ' +
            'Please verify @tanstack/react-router compatibility.',
        );
      }

      // Mark as SSR whenever we are hydrating a server-rendered page, even if
      // TanStack returned null dehydration data. This prevents Transitioner
      // from performing a client-only initial load during hydration.
      if (hasSsrPayload) {
        (router as any).ssr = true;
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

        // Only SSR hydration needs a manual load call.
        // For client-only renders, Transitioner handles initial loading.
        if (hasSsrPayload) {
          router.load().catch((err: unknown) => {
            console.error('react-on-rails/tanstack-router: Error loading routes after hydration:', err);
          });
        }
      }
    }, [hasSsrPayload]); // eslint-disable-line react-hooks/exhaustive-deps -- router is a ref, intentionally stable

    let app: ReactElement = createElement(RouterProvider, { router });
    if (options.AppWrapper) {
      const wrapperProps = { ...props } as Record<string, unknown>;
      delete wrapperProps.__tanstackRouterDehydratedState;
      app = createElement(options.AppWrapper, { ...wrapperProps, children: app } as any);
    }

    return app;
  };

  return createElement(AppComponent);
}
