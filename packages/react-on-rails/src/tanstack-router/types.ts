import type { ComponentType, ReactNode } from 'react';

/**
 * Minimal type for TanStack Router instance.
 * We use this instead of importing @tanstack/react-router directly
 * so the types work without the peer dependency installed.
 */
export interface TanStackRouter {
  update: (opts: { history: TanStackHistory }) => void;
  load: () => Promise<void>;
  matchRoutes: (
    pathnameOrLocation: string | { pathname: string; search?: unknown },
    locationSearch?: unknown,
    opts?: { throwOnError?: boolean },
  ) => unknown[];
  state: {
    status: string;
    location: {
      pathname: string;
      search?: unknown;
      searchStr?: string;
      hash?: string;
      href?: string;
    };
    resolvedLocation: unknown;
    matches: unknown[];
  };
  dehydrate?: () => unknown;
  hydrate?: (data: unknown) => void;
  // Internal APIs we need for sync SSR workaround
  __store?: {
    setState: (updater: (state: Record<string, unknown>) => Record<string, unknown>) => void;
  };
  // SSR flag (TanStack Start internal)
  ssr?: boolean;
}

export interface TanStackHistory {
  location: {
    pathname: string;
    search: string;
    hash: string;
    href: string;
    state: unknown;
  };
}

export interface TanStackRouterOptions {
  /**
   * Factory function that creates a TanStack Router instance.
   * Do NOT set history on the router — the wrapper will set it.
   *
   * @example
   * ```ts
   * import { createRouter } from '@tanstack/react-router';
   * import { routeTree } from './routeTree.gen';
   *
   * const App = createTanStackRouterRenderFunction({
   *   createRouter: () => createRouter({ routeTree }),
   * });
   * ```
   */
  createRouter: () => TanStackRouter;

  /**
   * Optional wrapper component for providers (QueryClient, Theme, etc.)
   * The router's RouterProvider will be rendered as children of this component.
   */
  AppWrapper?: ComponentType<{ children?: ReactNode } & Record<string, unknown>>;
}

/**
 * Dehydrated router state passed from server to client via props.
 */
export interface DehydratedRouterState {
  /** The URL that was server-rendered */
  url: string;
  /** Router dehydrated state from router.dehydrate() */
  dehydratedRouter: unknown;
}
