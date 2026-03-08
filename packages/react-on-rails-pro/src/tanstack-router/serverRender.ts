import { createElement, type ReactElement } from 'react';
import type {
  DehydratedRouterState,
  TanStackHistory,
  TanStackRouter,
  TanStackRouterOptions,
} from './types.ts';
import type { RailsContext } from 'react-on-rails/types';
import { normalizeSearch } from './utils.ts';

/**
 * Enables TanStack Router's internal SSR mode and verifies the flag is writable.
 */
function enableRouterSsrMode(router: TanStackRouter): void {
  const routerWithSsrFlag = router;
  routerWithSsrFlag.ssr = true;

  if (!routerWithSsrFlag.ssr) {
    throw new Error(
      'react-on-rails-pro/tanstack-router: Expected router.ssr to accept a boolean flag. ' +
        'Please check that your @tanstack/react-router version is compatible.',
    );
  }
}

/**
 * Builds a React element tree with RouterProvider and optional AppWrapper.
 */
function buildAppElement(
  router: TanStackRouter,
  RouterProvider: React.ComponentType<{ router: TanStackRouter }>,
  AppWrapper: TanStackRouterOptions['AppWrapper'],
  wrapperProps: Record<string, unknown>,
): ReactElement {
  let app: ReactElement = createElement(RouterProvider, { router });
  if (AppWrapper) {
    const safeWrapperProps = { ...wrapperProps };
    // eslint-disable-next-line no-underscore-dangle -- Internal hydration payload key should not reach user AppWrapper props.
    delete safeWrapperProps.__tanstackRouterDehydratedState;
    app = createElement(AppWrapper, safeWrapperProps, app);
  }
  return app;
}

export interface TanStackServerRenderResult {
  appElement: ReactElement;
  dehydratedState: DehydratedRouterState;
}

/**
 * Async server-side render for use with React on Rails Pro Node Renderer.
 * Uses the public router.load() API — no private API workarounds needed.
 *
 * Requires: rendering_returns_promises = true in React on Rails Pro config.
 */
export async function serverRenderTanStackAppAsync(
  options: TanStackRouterOptions,
  props: Record<string, unknown>,
  railsContext: RailsContext & { serverSide: true },
  RouterProvider: React.ComponentType<{ router: TanStackRouter }>,
  createMemoryHistory: (opts: { initialEntries: string[] }) => TanStackHistory,
): Promise<TanStackServerRenderResult> {
  const router = options.createRouter();
  const url = railsContext.pathname + normalizeSearch(railsContext.search);

  const memoryHistory = createMemoryHistory({ initialEntries: [url] });
  router.update({ history: memoryHistory });

  // Async path uses router.load() public API, so no private store access is needed.
  await router.load();

  // Ensure SSR output avoids client-only Suspense wrappers that can cause hydration mismatch.
  enableRouterSsrMode(router);

  const dehydratedState: DehydratedRouterState = {
    url,
    dehydratedRouter: typeof router.dehydrate === 'function' ? router.dehydrate() : null,
  };

  return {
    appElement: buildAppElement(router, RouterProvider, options.AppWrapper, props),
    dehydratedState,
  };
}
