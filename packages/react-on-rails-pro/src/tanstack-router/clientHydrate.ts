import { createElement, useEffect, useRef, type ComponentType, type ReactElement } from 'react';
import type {
  DehydratedRouterState,
  TanStackHistory,
  TanStackRouter,
  TanStackRouterOptions,
  TanStackSsrRouterState,
} from './types.ts';
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
  RouterClient?: ComponentType<{ router: TanStackRouter }>;
  createBrowserHistory: () => TanStackHistory;
}

interface TanStackSsrGlobal {
  router?: TanStackSsrRouterState;
  buffer: Array<() => void>;
  initialized?: boolean;
  hydrated?: boolean;
  streamEnded?: boolean;
  // These short keys are TanStack Router's upstream $_TSR bootstrap contract:
  // h = hydrated, e = stream ended, c = cleanup, p = run-or-buffer script.
  h: () => void;
  e: () => void;
  c: () => void;
  p: (script: () => void) => void;
}

function setTanStackSsrGlobal(ssrRouter: TanStackSsrRouterState): void {
  const globalState = window as unknown as Record<string, unknown>;
  const existing = globalState.$_TSR as TanStackSsrGlobal | undefined;
  const tsrGlobal: TanStackSsrGlobal = existing ?? {
    buffer: [],
    h() {
      this.hydrated = true;
    },
    e() {
      this.streamEnded = true;
    },
    c() {},
    p(script: () => void) {
      if (!this.initialized) {
        this.buffer.push(script);
        return;
      }

      script();
    },
  };

  tsrGlobal.router = ssrRouter;
  globalState.$_TSR = tsrGlobal;
}

function TanStackHydrationApp({
  options,
  incomingProps,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars -- Required by TanStackHydrationAppProps interface.
  railsContext: _railsContext,
  RouterProvider,
  RouterClient,
  createBrowserHistory,
}: TanStackHydrationAppProps): ReactElement {
  // eslint-disable-next-line no-underscore-dangle -- Internal hydration payload key injected by server-side render.
  const dehydratedState = incomingProps.__tanstackRouterDehydratedState as DehydratedRouterState | undefined;
  const ssrRouter = dehydratedState?.ssrRouter;
  const hasSsrPayload = dehydratedState !== undefined;
  const hasSsrRouter = ssrRouter !== undefined;
  const hasDehydratedRouter =
    dehydratedState?.dehydratedRouter !== undefined && dehydratedState.dehydratedRouter !== null;

  const routerRef = useRef<TanStackRouter | null>(null);
  const didTriggerPostHydrationLoadRef = useRef(false);
  const didInitializeSsrGlobalRef = useRef(false);

  if (routerRef.current === null) {
    const router = options.createRouter();

    // Set browser history for client-side navigation
    const browserHistory = createBrowserHistory();
    router.update({ history: browserHistory });

    // Hydrate router with dehydrated state from server.
    if (hasSsrRouter) {
      // RouterClient will hydrate the route matches from window.$_TSR.
    } else if (hasDehydratedRouter && typeof router.hydrate === 'function') {
      router.hydrate(dehydratedState.dehydratedRouter);
    } else if (hasDehydratedRouter) {
      throw new Error(
        'react-on-rails-pro/tanstack-router: Cannot hydrate SSR payload. ' +
          'router.hydrate() is required but not available on your TanStack Router version. ' +
          'Ensure @tanstack/react-router >=1.139.0 <2.0.0 is installed and provides router.hydrate().',
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

  if (hasSsrRouter && typeof window !== 'undefined' && !didInitializeSsrGlobalRef.current) {
    setTanStackSsrGlobal(ssrRouter);
    didInitializeSsrGlobalRef.current = true;
  }

  // After mount, trigger router.load() to enable client-side navigation.
  // The SSR flag prevented auto-loading, so we do it manually here.
  useEffect(() => {
    if (!router) {
      return undefined;
    }

    if (hasSsrRouter) {
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
  }, [hasSsrPayload, hasSsrRouter, router]);

  const RouterRoot =
    hasSsrRouter && typeof window !== 'undefined' && RouterClient ? RouterClient : RouterProvider;

  let app: ReactElement = createElement(RouterRoot, { router });
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
  RouterClient: ComponentType<{ router: TanStackRouter }> | undefined,
  createBrowserHistory: () => TanStackHistory,
): ReactElement {
  return createElement(TanStackHydrationApp, {
    options,
    incomingProps: props,
    railsContext,
    RouterProvider,
    RouterClient,
    createBrowserHistory,
  });
}
