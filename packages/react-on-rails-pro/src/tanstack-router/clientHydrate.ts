import { createElement, useEffect, useRef, type ReactElement } from 'react';
import type {
  DehydratedRouterState,
  TanStackHistory,
  TanStackRouter,
  TanStackRouterOptions,
} from './types.ts';
import type { RailsContext } from 'react-on-rails/types';

/* eslint-disable import/prefer-default-export, no-underscore-dangle */

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
 * 2. Synchronously inject route matches to match server-rendered output
 * 3. Set router.ssr to prevent Transitioner auto-load during hydration
 * 4. Hydrate with dehydrated router state if available
 * 5. After mount, clear SSR flag and trigger router.load()
 */

interface TanStackHydrationAppProps {
  options: TanStackRouterOptions;
  incomingProps: Record<string, unknown>;
  railsContext: RailsContext & { serverSide: false };
  RouterProvider: React.ComponentType<{ router: TanStackRouter }>;
  createBrowserHistory: () => TanStackHistory;
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

  if (routerRef.current === null) {
    const router = options.createRouter();

    // Set browser history for client-side navigation
    const browserHistory = createBrowserHistory();
    router.update({ history: browserHistory });

    // Synchronously inject route matches to match server-rendered output.
    // The server fully loads routes (via router.load()) before rendering, so
    // all matches are resolved with status 'idle'. We replicate this on the
    // client so the initial render produces the same component tree as the
    // server HTML. This uses the same __store.setState pattern as TanStack
    // Router's own hydrate() in @tanstack/router-core/ssr/ssr-client.js.
    const matches = router.matchRoutes(router.state.location);
    router.__store.setState((s: Record<string, unknown>) => ({
      ...s,
      status: 'idle',
      resolvedLocation: (s as { location: unknown }).location,
      matches,
    }));

    // Set SSR flag so the Transitioner skips its initial router.load() call,
    // preventing a state update during hydration that would cause a mismatch.
    // The shape matches TanStack Router's internal $_TSR hydration contract
    // (the Transitioner only checks truthiness).
    router.ssr = { manifest: undefined };

    // Hydrate router with dehydrated state from server if available.
    if (hasDehydratedRouter && typeof router.hydrate === 'function') {
      router.hydrate(dehydratedState.dehydratedRouter);
    }

    routerRef.current = router;
  }

  const router = routerRef.current;

  // After mount, clear the SSR flag and trigger router.load() to enable
  // client-side navigation. The SSR flag prevented auto-loading during
  // hydration, so we do it manually here.
  useEffect(() => {
    if (!router || !hasSsrPayload) {
      return undefined;
    }

    if (didTriggerPostHydrationLoadRef.current) {
      return undefined;
    }
    didTriggerPostHydrationLoadRef.current = true;

    // Clear the SSR flag so it doesn't affect subsequent navigations.
    router.ssr = undefined;

    let cancelled = false;
    router
      .load()
      .catch((err: unknown) => {
        if (!cancelled) {
          console.error('react-on-rails-pro/tanstack-router: Error loading routes after hydration:', err);
        }
      });

    return () => {
      cancelled = true;
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
  // See TanStackHydrationApp comment for why RouterProvider is used directly.
  _RouterClient: unknown,
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
