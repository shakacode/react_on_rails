import { createElement, useEffect, useRef, type ComponentType, type ReactElement } from 'react';
import type {
  DehydratedRouterState,
  TanStackHistory,
  TanStackRouter,
  TanStackRouterOptions,
  TanStackSsrMatch,
} from './types.ts';
import type { RailsContext } from 'react-on-rails/types';

/* eslint-disable import/prefer-default-export, no-underscore-dangle */

type TanStackRouterHydrationInternals = TanStackRouter & {
  matchRoutes: (location: unknown) => unknown[];
  __store: {
    setState: (updater: (s: Record<string, unknown>) => Record<string, unknown>) => void;
  };
};

type TanStackRouterChunkPreloadInternals = TanStackRouter & {
  loadRouteChunk?: (route: unknown) => Promise<unknown>;
  looseRoutesById?: Record<string, unknown>;
};

function extractDehydratedData(dehydratedRouter: unknown): unknown {
  if (!dehydratedRouter || typeof dehydratedRouter !== 'object') {
    return undefined;
  }
  return (dehydratedRouter as { dehydratedData?: unknown }).dehydratedData;
}

function preloadMatchedRouteChunks(
  router: TanStackRouterChunkPreloadInternals,
  matches: unknown[],
): Promise<void> | null {
  if (typeof router.loadRouteChunk !== 'function' || !router.looseRoutesById) {
    return null;
  }

  const routeChunkPromises: Array<Promise<unknown>> = [];
  matches.forEach((match) => {
    const { routeId } = match as { routeId?: unknown };
    if (typeof routeId !== 'string') {
      return;
    }

    const route = router.looseRoutesById?.[routeId];
    if (!route) {
      return;
    }

    routeChunkPromises.push(router.loadRouteChunk?.(route) as Promise<unknown>);
  });

  if (!routeChunkPromises.length) {
    return null;
  }

  return Promise.all(routeChunkPromises)
    .then(() => undefined)
    .catch((error: unknown) => {
      console.error('react-on-rails-pro/tanstack-router: Error preloading matched route chunks:', error);
    });
}

/**
 * Client-side hydration for a TanStack Router app.
 *
 * Uses RouterProvider directly (not RouterClient) to match the server-rendered
 * component tree. RouterClient wraps RouterProvider in <Await> which always
 * suspends on first render via defer(), causing a hydration mismatch because
 * the server renders RouterProvider directly without an <Await> wrapper.
 *
 * Flow:
 * 1. Create router with browser history
 * 2. If SSR payload exists, synchronously inject route matches to match server output
 * 3. Set router.ssr to prevent Transitioner auto-load during hydration
 * 4. Hydrate with dehydrated router state if available
 * 5. After mount, trigger router.load() and clear SSR flag once settled
 */

interface TanStackHydrationAppProps {
  options: TanStackRouterOptions;
  incomingProps: Record<string, unknown>;
  railsContext: RailsContext & { serverSide: false };
  RouterProvider: React.ComponentType<{ router: TanStackRouter }>;
  createBrowserHistory: () => TanStackHistory;
}

/**
 * Converts a dehydrated match ID (using \0 separator) back to the standard
 * route ID format (using / separator) used by matchRoutes().
 *
 * Inverse of dehydrateSsrMatchId() in serverRender.ts, which replaces '/'
 * with '\0' to match the $_TSR bootstrap wire format used by TanStack Router's
 * DehydrateRouter component (see @tanstack/react-router/src/DehydrateRouter.tsx).
 */
function rehydrateMatchId(dehydratedId: string): string {
  return dehydratedId.split('\0').join('/');
}

/**
 * Applies server-rendered match data (loaderData, beforeLoadContext, status, etc.)
 * from the dehydrated SSR payload to fresh client matches. This ensures the first
 * client render can access the same data the server used, preventing mismatches
 * for routes that render from loader results.
 */
function applyDehydratedMatchData(matches: unknown[], ssrMatches: TanStackSsrMatch[]): unknown[] {
  return matches.map((match) => {
    const m = match as Record<string, unknown>;
    const ssrMatch = ssrMatches.find((sm) => rehydrateMatchId(sm.i) === m.id);

    if (ssrMatch) {
      return {
        ...m,
        status: ssrMatch.s,
        updatedAt: ssrMatch.u,
        ...(ssrMatch.l !== undefined ? { loaderData: ssrMatch.l } : {}),
        ...(ssrMatch.b !== undefined ? { __beforeLoadContext: ssrMatch.b } : {}),
        ...(ssrMatch.e !== undefined ? { error: ssrMatch.e } : {}),
        ...(ssrMatch.ssr !== undefined ? { ssr: ssrMatch.ssr } : {}),
      };
    }

    // No server match — override pending to success to prevent MatchInner
    // from throwing loadPromise (which would cause Suspense suspension).
    if (m.status === 'pending') {
      return { ...m, status: 'success' };
    }

    return m;
  });
}

function TanStackHydrationApp({
  options,
  incomingProps,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars -- Required by TanStackHydrationAppProps interface.
  railsContext: _railsContext,
  RouterProvider,
  createBrowserHistory,
}: TanStackHydrationAppProps): ReactElement {
  const dehydratedState = incomingProps.__tanstackRouterDehydratedState as
    | DehydratedRouterState
    | null
    | undefined;
  const hasSsrPayload = dehydratedState != null;
  const hasDehydratedRouter =
    dehydratedState?.dehydratedRouter !== undefined && dehydratedState.dehydratedRouter !== null;

  const routerRef = useRef<TanStackRouter | null>(null);
  const didTriggerPostHydrationLoadRef = useRef(false);
  const didSetSsrFlagRef = useRef(false);
  const routeChunkPreloadPromiseRef = useRef<Promise<void> | null>(null);

  if (routerRef.current === null) {
    const router = options.createRouter();

    // Set browser history for client-side navigation
    const browserHistory = createBrowserHistory();
    router.update({ history: browserHistory });

    // Only apply SSR hydration when a server payload exists.
    // Client-only renders (prerender: false) must not set router.ssr or
    // inject matches — the Transitioner handles initial loading for those.
    if (hasSsrPayload) {
      // Validate internal APIs before using them.
      if (typeof router.matchRoutes !== 'function' || !router.__store?.setState) {
        throw new Error(
          'react-on-rails-pro/tanstack-router: router.matchRoutes() and router.__store are required ' +
            'but not available. Ensure @tanstack/react-router >=1.139.0 <2.0.0 is installed.',
        );
      }
      const hydrationRouter = router as TanStackRouterHydrationInternals;

      // Synchronously inject route matches to match server-rendered output.
      // The server fully loads routes (via router.load()) before rendering, so
      // all matches are resolved. We replicate this on the client so the initial
      // render produces the same component tree as the server HTML.
      //
      // When ssrRouter match data is available (from serverRenderTanStackAppAsync),
      // we apply loaderData, beforeLoadContext, status, etc. from the server payload
      // so routes that render from loader results can hydrate correctly.
      // Otherwise we override 'pending' to 'success' to prevent MatchInner from
      // throwing loadPromise (which would cause Suspense suspension).
      const rawMatches = hydrationRouter.matchRoutes(hydrationRouter.state.location);
      routeChunkPreloadPromiseRef.current = preloadMatchedRouteChunks(
        router as TanStackRouterChunkPreloadInternals,
        rawMatches,
      );
      const ssrMatches = dehydratedState?.ssrRouter?.matches;
      const matches = ssrMatches?.length
        ? applyDehydratedMatchData(rawMatches, ssrMatches)
        : rawMatches.map((match) => {
            const m = match as Record<string, unknown>;
            return m.status === 'pending' ? { ...m, status: 'success' } : m;
          });

      hydrationRouter.__store.setState((s: Record<string, unknown>) => ({
        ...s,
        status: 'idle',
        resolvedLocation: (s as { location: unknown }).location,
        matches,
      }));

      // Set SSR flag so the Transitioner skips its initial router.load() call,
      // preventing a state update during hydration that would cause a mismatch.
      // The shape matches TanStack Router's internal $_TSR hydration contract
      // (the Transitioner only checks truthiness).
      // Preserve user-set values from createRouter() (e.g. TanStack Start).
      if (!router.ssr) {
        router.ssr = { manifest: undefined };
        didSetSsrFlagRef.current = true;
      }

      try {
        // Run user-defined hydration callback for custom dehydratedData
        // (for example external query/cache payloads), matching TanStack
        // Router's ssr-client behavior.
        if (typeof router.options?.hydrate === 'function') {
          const hydrationResult = router.options.hydrate(
            extractDehydratedData(dehydratedState?.dehydratedRouter),
          );
          void Promise.resolve(hydrationResult).catch((error: unknown) => {
            console.error(
              'react-on-rails-pro/tanstack-router: Error in router.options.hydrate callback:',
              error,
            );
          });
        }

        // Backward-compatibility hook: if user router exposes router.hydrate(),
        // invoke it with the full dehydrated router payload.
        if (hasDehydratedRouter && typeof router.hydrate === 'function') {
          router.hydrate(dehydratedState.dehydratedRouter);
        }
      } catch (error) {
        // If render-phase hydration throws, clear only the temporary SSR flag
        // created by this module so retries are not blocked.
        if (didSetSsrFlagRef.current) {
          router.ssr = undefined;
          didSetSsrFlagRef.current = false;
        }
        throw error;
      }
    }

    routerRef.current = router;
  }

  const router = routerRef.current;

  // After mount, trigger router.load() to enable client-side navigation.
  // The SSR flag prevented auto-loading, so we do it manually here.
  useEffect(() => {
    if (!router || !hasSsrPayload) {
      return undefined;
    }

    if (didTriggerPostHydrationLoadRef.current) {
      return undefined;
    }
    didTriggerPostHydrationLoadRef.current = true;

    let cancelled = false;
    const runPostHydrationLoad = async (): Promise<void> => {
      if (routeChunkPreloadPromiseRef.current) {
        await routeChunkPreloadPromiseRef.current;
      }
      await router.load();
    };

    void runPostHydrationLoad()
      .catch((err: unknown) => {
        if (!cancelled) {
          console.error('react-on-rails-pro/tanstack-router: Error loading routes after hydration:', err);
        }
      })
      .finally(() => {
        // Always clear temporary router.ssr set by this module, regardless of
        // cancellation state. In React 18 StrictMode, the effect cleanup sets
        // cancelled=true and didTriggerPostHydrationLoadRef prevents re-trigger
        // on re-mount — if we skip cleanup here the SSR flag stays set
        // permanently, blocking the Transitioner from ever calling router.load().
        // The didSetSsrFlagRef guard ensures we only clear values this module
        // created, preserving user-provided router.ssr from createRouter().
        if (didSetSsrFlagRef.current) {
          router.ssr = undefined;
          didSetSsrFlagRef.current = false;
        }
      });

    return () => {
      cancelled = true;
      if (didSetSsrFlagRef.current) {
        router.ssr = undefined;
        didSetSsrFlagRef.current = false;
      }
      const cancellableRouter = router as TanStackRouter & { cancelLoad?: () => void };
      if (typeof cancellableRouter.cancelLoad === 'function') {
        cancellableRouter.cancelLoad();
      }
    };
  }, [hasSsrPayload, router]);

  // Always use RouterProvider directly — matching the server-rendered tree.
  // RouterClient is NOT used because it wraps RouterProvider in <Await> which
  // introduces a Suspense boundary that doesn't exist in the server HTML,
  // causing React hydration mismatch errors.
  let app: ReactElement = createElement(RouterProvider, { router });
  if (options.AppWrapper) {
    const wrapperProps = { ...incomingProps } as Record<string, unknown>;
    delete wrapperProps.__tanstackRouterDehydratedState;
    app = createElement(options.AppWrapper, wrapperProps, app);
  }

  return app;
}

export function clientHydrateTanStackApp(
  options: TanStackRouterOptions,
  props: Record<string, unknown>,
  railsContext: RailsContext & { serverSide: false },
  RouterProvider: React.ComponentType<{ router: TanStackRouter }>,
  // RouterClient is accepted for backward compatibility but intentionally unused.
  // See TanStackHydrationApp JSDoc for why RouterProvider is used directly.
  _RouterClient: ComponentType<{ router: TanStackRouter }> | undefined,
  createBrowserHistory: () => TanStackHistory,
): ReactElement {
  return createElement(TanStackHydrationApp, {
    options,
    incomingProps: props,
    railsContext,
    RouterProvider,
    createBrowserHistory,
  });
}
