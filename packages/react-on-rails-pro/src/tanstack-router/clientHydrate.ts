import { createElement, useEffect, useRef, type ReactElement } from 'react';
import type { DehydratedRouterState, TanStackHistory, TanStackRouter, TanStackRouterOptions } from './types.ts';
import type { RailsContext } from 'react-on-rails/types';

/* eslint-disable import/prefer-default-export */

/**
 * Client-side hydration for a TanStack Router app.
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

function TanStackHydrationApp({
  options,
  incomingProps,
  railsContext: _railsContext,
  RouterProvider,
  createBrowserHistory,
}: TanStackHydrationAppProps): ReactElement {
  // eslint-disable-next-line no-underscore-dangle -- Internal hydration payload key injected by server-side render.
  const dehydratedState = incomingProps.__tanstackRouterDehydratedState as DehydratedRouterState | undefined;
  const hasSsrPayload = dehydratedState !== undefined;
  const hasDehydratedRouter =
    dehydratedState?.dehydratedRouter !== undefined && dehydratedState.dehydratedRouter !== null;

  const routerRef = useRef<TanStackRouter | null>(null);
  const didTriggerPostHydrationLoadRef = useRef(false);

  if (routerRef.current === null) {
    const router = options.createRouter();

    // Set browser history for client-side navigation
    const browserHistory = createBrowserHistory();
    router.update({ history: browserHistory });

    // Hydrate router with dehydrated state from server.
    if (hasSsrPayload && hasDehydratedRouter && typeof router.hydrate === 'function') {
      router.hydrate(dehydratedState.dehydratedRouter);
    } else if (hasSsrPayload) {
      throw new Error(
        'react-on-rails-pro/tanstack-router: Cannot hydrate SSR payload. ' +
          'router.hydrate() is required but not available on your TanStack Router version. ' +
          'Ensure @tanstack/react-router >=1.139.0 <2.0.0 is installed and provides router.hydrate().',
      );
    }

    // Keep SSR mode enabled on hydration paths so Transitioner does not run
    // a client-only initial load before hydration settles.
    if (hasSsrPayload && router.ssr !== true) {
      router.ssr = true;
    }

    routerRef.current = router;
  }

  const router = routerRef.current;

  // After mount, trigger router.load() to enable client-side navigation.
  // The SSR flag prevented auto-loading, so we do it manually here.
  useEffect(() => {
    if (!router) {
      return undefined;
    }

    // Only SSR hydration needs a manual load call.
    // For client-only renders, Transitioner handles initial loading.
    if (!hasSsrPayload) {
      return undefined;
    }

    if (didTriggerPostHydrationLoadRef.current) {
      return undefined;
    }
    didTriggerPostHydrationLoadRef.current = true;

    let cancelled = false;
    router.load().catch((err: unknown) => {
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

  let app: ReactElement = createElement(RouterProvider, { router });
  if (options.AppWrapper) {
    const wrapperProps = { ...incomingProps } as Record<string, unknown>;
    // eslint-disable-next-line no-underscore-dangle -- Internal hydration payload key should not reach user AppWrapper props.
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
