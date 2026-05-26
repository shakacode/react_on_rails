import type { ComponentType, ReactNode } from 'react';

/**
 * Shape of a writable TanStack store atom. Used by the modern `router.stores`
 * API exposed on TanStackRouter below.
 *
 * `set` is declared as an overload to match the upstream `@tanstack/store`
 * `Atom.set` signature (which is an overload, not a union parameter); a union
 * parameter would not be structurally assignable from the upstream type.
 */
export type TanStackRouterWritableStore<TValue = unknown> = {
  set: ((value: TValue) => void) & ((updater: (prev: TValue) => TValue) => void);
};

/**
 * Minimal type for TanStack Router instance.
 * We use this instead of importing @tanstack/react-router directly
 * so the types work without the peer dependency installed.
 */
export interface TanStackRouter {
  update: (opts: { history: TanStackHistory }) => void;
  load: () => Promise<void>;
  // Internal TanStack Router APIs used only by the hydration workaround.
  // Kept optional in the public type so consumers/mocks are not forced
  // to model private internals — but exposed here (rather than via casts
  // in clientHydrate.ts) so tests can populate or `delete` them without a
  // type assertion, mirroring how `__store` is modeled.
  matchRoutes?: (location: unknown) => unknown[];
  __store?: {
    setState: (updater: (s: Record<string, unknown>) => Record<string, unknown>) => void;
  };
  // Modern stores API that replaces `__store` in newer @tanstack/react-router
  // 1.x releases. Either this OR `__store` must be available for SSR hydration;
  // clientHydrate.ts prefers `__store` when both are present.
  stores?: {
    status: TanStackRouterWritableStore<string>;
    resolvedLocation: TanStackRouterWritableStore<TanStackRouter['state']['location']>;
    // setMatches is a batch-utility helper on the stores object, not a store
    // atom with a `.set()` method — that's why it doesn't follow the
    // TanStackRouterWritableStore<T> pattern used by the siblings above.
    setMatches: (nextMatches: unknown[]) => void;
  };
  // Optional companion of the stores API: batches multiple store writes into
  // a single subscriber notification, matching __store.setState's atomicity.
  batch?: (callback: () => void) => void;
  looseRoutesById?: Record<string, unknown>;
  loadRouteChunk?: (route: unknown) => Promise<unknown>;
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
  options?: {
    hydrate?: (dehydratedData: unknown) => Promise<unknown> | unknown;
  };
  // TanStack Router's Transitioner checks this field (truthiness only) to skip
  // auto-loading on mount.  The canonical shape is { manifest?: unknown }.
  // Set during client hydration to prevent a duplicate initial load that
  // causes hydration mismatch.
  ssr?: { manifest?: unknown };
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

/**
 * Dehydrated SSR match payload. The single-char keys match TanStack Router's
 * upstream `$_TSR` bootstrap wire format — they must NOT be renamed.
 */
export interface TanStackSsrMatch {
  /** id — route match identifier */
  i: string;
  /** updatedAt — timestamp of last update */
  u: number;
  /** status — match resolution status */
  s: string;
  /** beforeLoadContext */
  b?: unknown;
  /** loaderData */
  l?: unknown;
  /** error */
  e?: unknown;
  ssr?: unknown;
}

export interface TanStackSsrRouterState {
  manifest?: unknown;
  dehydratedData?: unknown;
  lastMatchId?: string;
  matches: TanStackSsrMatch[];
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
  /** Legacy TanStack SSR match payload used for compatibility and match-data restoration during hydration */
  ssrRouter?: TanStackSsrRouterState;
}
