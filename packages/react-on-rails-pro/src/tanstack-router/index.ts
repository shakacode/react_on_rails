/**
 * TanStack Router integration for React on Rails Pro.
 *
 * This module provides utilities to use TanStack Router with React on Rails Pro's
 * async Node Renderer SSR pipeline. It requires `rendering_returns_promises = true`
 * in your React on Rails Pro configuration.
 *
 * @example
 * ```typescript
 * import { createTanStackRouterRenderFunction } from 'react-on-rails-pro/tanstack-router';
 * import { createRouter, RouterProvider, createMemoryHistory, createBrowserHistory } from '@tanstack/react-router';
 * import { routeTree } from './routeTree.gen';
 * import ReactOnRails from 'react-on-rails';
 *
 * const TanStackApp = createTanStackRouterRenderFunction(
 *   {
 *     createRouter: () => createRouter({ routeTree }),
 *   },
 *   { RouterProvider, createMemoryHistory, createBrowserHistory },
 * );
 *
 * ReactOnRails.register({ TanStackApp });
 * ```
 *
 * @remarks
 * TanStack Router SSR requires React on Rails Pro with the Node Renderer.
 * If you encounter issues after upgrading @tanstack/react-router, update react-on-rails-pro
 * or file an issue at https://github.com/shakacode/react_on_rails/issues
 *
 * @packageDocumentation
 */

import type { RailsContext, RenderFunction, RenderFunctionResult, ServerRenderResult } from 'react-on-rails/types';
import type { TanStackHistory, TanStackRouter, TanStackRouterOptions } from './types.ts';
import { serverRenderTanStackAppAsync } from './serverRender.ts';
import { clientHydrateTanStackApp } from './clientHydrate.ts';

export type { TanStackRouterOptions, DehydratedRouterState } from './types.ts';
export { serverRenderTanStackAppAsync } from './serverRender.ts';

interface TanStackRouterDeps {
  /**
   * The RouterProvider component from @tanstack/react-router.
   * We require this as a parameter to avoid a direct dependency on @tanstack/react-router.
   */
  RouterProvider: React.ComponentType<{ router: TanStackRouter }>;
  /**
   * The createMemoryHistory function from @tanstack/react-router.
   * Used for server-side rendering.
   */
  createMemoryHistory: (opts: { initialEntries: string[] }) => TanStackHistory;
  /**
   * The createBrowserHistory function from @tanstack/react-router.
   * Used for client-side hydration.
   */
  createBrowserHistory: () => TanStackHistory;
}

/**
 * Creates a React on Rails render function for a TanStack Router application.
 *
 * This function returns a render function that can be registered with `ReactOnRails.register()`.
 * On the server, it uses the async `router.load()` API via React on Rails Pro's Node Renderer.
 * On the client, it hydrates using the dehydrated router state from the server.
 *
 * Requires `rendering_returns_promises = true` in your React on Rails Pro configuration.
 *
 * @param options - Configuration for the TanStack Router app
 * @param deps - TanStack Router dependencies (RouterProvider, createMemoryHistory, createBrowserHistory)
 * @returns A render function compatible with ReactOnRails.register()
 */
export function createTanStackRouterRenderFunction(
  options: TanStackRouterOptions,
  deps: TanStackRouterDeps,
): RenderFunction {
  const { RouterProvider, createMemoryHistory, createBrowserHistory } = deps;

  const renderFn = (
    props: Record<string, unknown> = {},
    railsContext?: RailsContext,
  ): RenderFunctionResult => {
    if (!railsContext) {
      throw new Error(
        'react-on-rails-pro/tanstack-router: railsContext is required. ' +
          'Ensure the component is rendered via react_component helper.',
      );
    }

    if (railsContext.serverSide) {
      // Returns a Promise — requires rendering_returns_promises = true in Pro config.
      return serverRenderTanStackAppAsync(
        options,
        props,
        railsContext as RailsContext & { serverSide: true },
        RouterProvider,
        createMemoryHistory,
      ).then(({ appElement, dehydratedState }) => ({
        renderedHtml: appElement,
        clientProps: {
          __tanstackRouterDehydratedState: dehydratedState,
        },
      })) as RenderFunctionResult;
    }

    // Client-side: return a React component so React on Rails can instantiate it with props.
    return function TanStackRouterClientApp(clientProps: Record<string, unknown> = {}) {
      return clientHydrateTanStackApp(
        options,
        clientProps,
        railsContext as RailsContext & { serverSide: false },
        RouterProvider,
        createBrowserHistory,
      );
    };
  };

  // Mark as a render function so React on Rails executes it rather than treating it
  // as a React component.
  renderFn.renderFunction = true as const;

  return renderFn;
}
