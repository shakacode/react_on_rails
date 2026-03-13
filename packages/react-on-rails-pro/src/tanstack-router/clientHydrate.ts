import { Suspense, createElement, useEffect, useRef, type ReactElement } from 'react';
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

interface RouteChunkPreloadGateProps {
  preloadPromise: Promise<void> | null;
  preloadSettledRef: { current: boolean };
  isHydrating?: boolean;
  children?: ReactElement;
}

function RouteChunkPreloadGate({
  preloadPromise,
  preloadSettledRef,
  isHydrating,
  children,
}: RouteChunkPreloadGateProps): ReactElement {
  // During SSR hydration (first render), skip the suspension gate to avoid a
  // hydration mismatch: the server rendered RouterProvider content directly,
  // so throwing a promise here would cause Suspense to render the null fallback
  // instead of matching the server HTML. After hydration completes (the
  // post-mount effect sets didTriggerPostHydrationLoadRef), the gate activates
  // normally for any subsequent re-renders.
  if (!isHydrating && preloadPromise && !preloadSettledRef.current) {
    // eslint-disable-next-line @typescript-eslint/only-throw-error -- Suspense boundaries intentionally suspend on thrown Promise.
    throw preloadPromise;
  }
  return children as ReactElement;
}

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

    routeChunkPromises.push(loadRouteChunk(route));
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
 * 2. Hydrate from dehydrated state provided by serverRenderTanStackAppAsync
 * 3. Set router.ssr = true to skip auto-load on mount (Transitioner behavior)
 * 4. After hydration, trigger router.load() to enable client-side navigation
 * 5. Return a React component that renders RouterProvider
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
  const didInitializeSsrGlobalRef = useRef(false);

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

    // Keep SSR mode enabled on hydration paths so Transitioner does not run
    // a client-only initial load before hydration settles.
    if (!hasSsrRouter && hasSsrPayload && router.ssr !== true) {
      router.ssr = true;
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
    // `cancelled` only suppresses logging for a discarded mount. The in-flight load still
    // completes unless the router exposes a best-effort cancelLoad() hook.
    router.load().catch((err: unknown) => {
      if (!cancelled) {
        console.error('react-on-rails-pro/tanstack-router: Error loading routes after hydration:', err);
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
  //
  // RouteChunkPreloadGate blocks re-renders until matched lazy chunks finish
  // preloading (when preload support is available). During the initial SSR
  // hydration render, the gate is skipped to match the server-rendered tree
  // and avoid a hydration mismatch. After the post-mount effect runs
  // (didTriggerPostHydrationLoadRef becomes true), the gate activates normally.
  let app: ReactElement = createElement(
    Suspense,
    { fallback: null },
    createElement(
      RouteChunkPreloadGate,
      {
        preloadPromise: routeChunkPreloadPromiseRef.current,
        preloadSettledRef: routeChunkPreloadSettledRef,
        isHydrating: hasSsrPayload && !didTriggerPostHydrationLoadRef.current,
      },
      createElement(RouterProvider, { router }),
    ),
  );
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
): ReactElement {
  return createElement(TanStackHydrationApp, {
    options,
    incomingProps: props,
    railsContext,
    RouterProvider,
    createBrowserHistory,
  });
}
