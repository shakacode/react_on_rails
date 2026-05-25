import * as React from 'react';
import type {
  DehydratedRouterState,
  TanStackHistory,
  TanStackRouter,
  TanStackRouterOptions,
  TanStackSsrMatch,
} from './types.ts';
import type { RailsContext } from 'react-on-rails/types';

/* eslint-disable import/prefer-default-export, no-underscore-dangle */

const { createElement, useEffect, useRef } = React;

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

// Render-phase initialization can be replayed before commit in StrictMode. Reuse
// in-flight route chunk preloads so replay does not request the same chunk twice.
const routeChunkPreloadPromisesByRouter = new WeakMap<
  TanStackRouterChunkPreloadInternals,
  WeakMap<object, Promise<unknown>>
>();

function extractDehydratedData(dehydratedRouter: unknown): unknown {
  if (!dehydratedRouter || typeof dehydratedRouter !== 'object') {
    return undefined;
  }
  return (dehydratedRouter as { dehydratedData?: unknown }).dehydratedData;
}

function preloadRouteChunk(router: TanStackRouterChunkPreloadInternals, route: unknown): Promise<unknown> {
  const { loadRouteChunk } = router;
  if (typeof loadRouteChunk !== 'function') {
    return Promise.resolve();
  }

  if (!route || typeof route !== 'object') {
    return loadRouteChunk(route);
  }

  let routeChunkPreloadPromises = routeChunkPreloadPromisesByRouter.get(router);
  if (!routeChunkPreloadPromises) {
    routeChunkPreloadPromises = new WeakMap<object, Promise<unknown>>();
    routeChunkPreloadPromisesByRouter.set(router, routeChunkPreloadPromises);
  }

  const existingPromise = routeChunkPreloadPromises.get(route);
  if (existingPromise) {
    return existingPromise;
  }

  let loadPromise: Promise<unknown>;
  try {
    loadPromise = Promise.resolve(loadRouteChunk(route));
  } catch (error) {
    return Promise.reject(error instanceof Error ? error : new Error(String(error)));
  }

  const cachedPromise = loadPromise.finally(() => {
    if (routeChunkPreloadPromises.get(route) === cachedPromise) {
      routeChunkPreloadPromises.delete(route);
    }
  });
  routeChunkPreloadPromises.set(route, cachedPromise);

  return cachedPromise;
}

function preloadMatchedRouteChunks(
  router: TanStackRouterChunkPreloadInternals,
  matches: unknown[],
): Promise<void> | null {
  const { loadRouteChunk, looseRoutesById } = router;
  if (typeof loadRouteChunk !== 'function' || !looseRoutesById) {
    return null;
  }

  const routeChunkPromises: Array<Promise<unknown>> = [];
  matches.forEach((match) => {
    const { routeId } = match as { routeId?: unknown };
    if (typeof routeId !== 'string') {
      return;
    }

    const route = looseRoutesById[routeId];
    if (!route) {
      return;
    }

    routeChunkPromises.push(preloadRouteChunk(router, route));
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
function applyDehydratedMatchData(
  matches: unknown[],
  ssrMatches: TanStackSsrMatch[],
  onMissingSsrMatch?: (match: Record<string, unknown>) => void,
): unknown[] {
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
      onMissingSsrMatch?.(m);
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
}: TanStackHydrationAppProps): React.ReactElement {
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
  const latestEffectRunIdRef = useRef(0); // 0 = no post-hydration effect run yet.
  // Set during render-phase SSR init; awaited in runPostHydrationLoad before
  // router.load() so post-hydration navigation waits for matched lazy chunks.
  const routeChunkPreloadPromiseRef = useRef<Promise<void> | null>(null);
  const hydrationCallbackPromiseRef = useRef<Promise<void> | null>(null);
  const didWarnPrivateInternalsRef = useRef(false);
  const warnedMissingSsrMatchIdsRef = useRef<Set<string>>(new Set());

  const warnMissingSsrMatch = (match: Record<string, unknown>): void => {
    if (process.env.NODE_ENV !== 'development') {
      return;
    }
    const routeId =
      typeof match.id === 'string' || typeof match.id === 'number' ? String(match.id) : '<unknown>';
    if (warnedMissingSsrMatchIdsRef.current.has(routeId)) {
      return;
    }
    warnedMissingSsrMatchIdsRef.current.add(routeId);
    console.warn(
      `react-on-rails-pro/tanstack-router: No server match found for route "${routeId}". ` +
        'Overriding match.status from "pending" to "success" to prevent hydration suspension.',
    );
  };

  if (routerRef.current === null) {
    // Intentionally initialize the hydration router during render so the very
    // first RouterProvider render sees SSR-injected matches and the temporary
    // router.ssr flag. Moving this to an effect causes a first-render mismatch
    // (the provider would render before hydration state is injected).
    //
    // Safety invariant: all mutations in this block target only the router
    // instance created here and routerRef.current is assigned only after the
    // block completes. If React discards this render (StrictMode/concurrency),
    // the discarded router instance is dropped and a fresh instance is created
    // and initialized on the next render.
    const router = options.createRouter();

    // Set browser history for client-side navigation
    const browserHistory = createBrowserHistory();
    router.update({ history: browserHistory });

    // Only apply SSR hydration when a server payload exists.
    // Client-only renders (prerender: false) must not set router.ssr or
    // inject matches — the Transitioner handles initial loading for those.
    if (hasSsrPayload) {
      if (process.env.NODE_ENV === 'development' && !didWarnPrivateInternalsRef.current) {
        didWarnPrivateInternalsRef.current = true;
        console.warn(
          'react-on-rails-pro/tanstack-router: Hydration uses TanStack Router private internals ' +
            '(matchRoutes, __store, loadRouteChunk, looseRoutesById). Keep @tanstack/react-router ' +
            'within the supported range (>=1.139.0 <2.0.0) and run integration tests when upgrading.',
        );
      }

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
        ? applyDehydratedMatchData(rawMatches, ssrMatches, warnMissingSsrMatch)
        : rawMatches.map((match) => {
            const m = match as Record<string, unknown>;
            if (m.status === 'pending') {
              warnMissingSsrMatch(m);
              return { ...m, status: 'success' };
            }
            return m;
          });

      // Render-phase store injection is required for hydration parity: this
      // must happen before the first RouterProvider render.
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
          // Let async hydration failures reject so we do not continue into
          // router.load() with partially hydrated client state.
          hydrationCallbackPromiseRef.current = Promise.resolve(hydrationResult).then(() => undefined);
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
    const effectRunId = latestEffectRunIdRef.current + 1;
    latestEffectRunIdRef.current = effectRunId;

    // Dev-mode sanity check: router.ssr should still hold the value we wrote
    // during render-phase init. Our window-safety argument (parent re-renders
    // are safe because router.ssr blocks Transitioner navigation) depends on
    // a private TanStack Router API. If that API is renamed or removed in a
    // future version, this warning surfaces the breakage before it manifests
    // as a hard-to-diagnose navigation race.
    if (process.env.NODE_ENV === 'development' && didSetSsrFlagRef.current && router.ssr == null) {
      console.warn(
        'react-on-rails-pro/tanstack-router: router.ssr was unexpectedly ' +
          'cleared between render-phase init and the post-hydration effect. ' +
          'TanStack Router\'s private "ssr" API may have changed — verify ' +
          '@tanstack/react-router is within the supported range ' +
          '(>=1.139.0 <2.0.0).',
      );
    }

    let cancelled = false;
    const runPostHydrationLoad = async (): Promise<void> => {
      if (hydrationCallbackPromiseRef.current) {
        await hydrationCallbackPromiseRef.current;
        if (cancelled) {
          return;
        }
      }
      if (routeChunkPreloadPromiseRef.current) {
        await routeChunkPreloadPromiseRef.current;
        if (cancelled) {
          return;
        }
      }
      // No final cancellation check is needed for the no-await fast path:
      // without pending hydration or preload promises, cleanup cannot run between
      // the checks above and this call. If unmount happens after router.load()
      // starts, the cleanup's cancelLoad() call handles the in-flight load.
      await router.load();
    };

    void runPostHydrationLoad()
      .catch((err: unknown) => {
        if (!cancelled) {
          console.error('react-on-rails-pro/tanstack-router: Error loading routes after hydration:', err);
        }
      })
      .finally(() => {
        // Invariant: temporary router.ssr is cleared by exactly one path:
        //   1. this finally block after the post-hydration load settles/cancels;
        //   2. this effect cleanup's deferred continuation when unmount happens
        //      before that settle.
        // didSetSsrFlagRef is the shared latch, preserving user-provided
        // router.ssr from createRouter(). latestEffectRunIdRef prevents stale
        // StrictMode passive-effect finally blocks from racing a remount. Today
        // React runs passive cleanup/setup inside one synchronous
        // flushPassiveEffects() call, so queued promise continuations cannot
        // drain between the cleanup and the re-setup.
        if (latestEffectRunIdRef.current === effectRunId && didSetSsrFlagRef.current) {
          router.ssr = undefined;
          didSetSsrFlagRef.current = false;
        }
      });

    return () => {
      cancelled = true;
      didTriggerPostHydrationLoadRef.current = false;
      // Defer the unmount clear so React 18 StrictMode's passive cleanup/setup
      // replay can increment latestEffectRunIdRef before this continuation runs.
      void Promise.resolve().then(() => {
        if (latestEffectRunIdRef.current === effectRunId && didSetSsrFlagRef.current) {
          router.ssr = undefined;
          didSetSsrFlagRef.current = false;
        }
      });
      const cancellableRouter = router as TanStackRouter & { cancelLoad?: () => void };
      if (typeof cancellableRouter.cancelLoad === 'function') {
        cancellableRouter.cancelLoad();
      }
    };
  }, [hasSsrPayload, router]);

  // Render RouterProvider directly — matching the server-rendered tree
  // (AppWrapper > RouterProvider). Any extra Suspense boundary here produces
  // a shape mismatch during hydration and React bails to full client-side
  // rendering. The old RouteChunkPreloadGate also suspended re-renders during
  // chunk preload; that behavior is intentionally not replicated here because
  // chunk-preload sequencing is enforced by runPostHydrationLoad before
  // router.load(). A consequence is that any parent-triggered re-render
  // landing in the window between render-phase preload init and
  // runPostHydrationLoad completion now reaches RouterProvider unguarded —
  // safe because router.ssr blocks Transitioner-initiated navigation across
  // that window, and the route components themselves throw their own
  // Suspense promises if a chunk is still loading.
  let app: React.ReactElement = createElement(RouterProvider, { router });
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
  createBrowserHistory: () => TanStackHistory,
): React.ReactElement {
  return createElement(TanStackHydrationApp, {
    options,
    incomingProps: props,
    railsContext,
    RouterProvider,
    createBrowserHistory,
  });
}
