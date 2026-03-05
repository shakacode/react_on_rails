/**
 * TanStack Router integration for React on Rails.
 *
 * This module provides utilities to use TanStack Router with React on Rails' SSR pipeline.
 * It encapsulates the workarounds needed for synchronous server-side rendering
 * (TanStack Router's route loading is async, but renderToString is sync).
 *
 * @example
 * ```typescript
 * import { createTanStackRouterRenderFunction } from 'react-on-rails/tanstack-router';
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
 * This integration uses internal TanStack Router APIs for synchronous SSR.
 * ShakaCode maintains compatibility with TanStack Router versions.
 * If you encounter issues after upgrading @tanstack/react-router, update react-on-rails
 * or file an issue at https://github.com/shakacode/react_on_rails/issues
 *
 * @packageDocumentation
 */

import type {
  RailsContext,
  RenderFunction,
  RenderFunctionResult,
  ServerRenderResult,
} from '../types/index.ts';
import type { TanStackRouterOptions } from './types.ts';
import { serverRenderTanStackApp } from './serverRender.ts';
import { clientHydrateTanStackApp } from './clientHydrate.ts';

export type { TanStackRouterOptions, DehydratedRouterState } from './types.ts';
export { serverRenderTanStackAppAsync } from './serverRender.ts';

/* eslint-disable @typescript-eslint/no-explicit-any, @typescript-eslint/no-unsafe-return */

interface TanStackRouterDeps {
  /**
   * The RouterProvider component from @tanstack/react-router.
   * We require this as a parameter to avoid a direct dependency on @tanstack/react-router.
   */
  RouterProvider: React.ComponentType<any>;
  /**
   * The createMemoryHistory function from @tanstack/react-router.
   * Used for server-side rendering.
   */
  createMemoryHistory: (opts: { initialEntries: string[] }) => any;
  /**
   * The createBrowserHistory function from @tanstack/react-router.
   * Used for client-side hydration.
   */
  createBrowserHistory: () => any;
}

/**
 * Creates a React on Rails render function for a TanStack Router application.
 *
 * This function returns a render function that can be registered with `ReactOnRails.register()`.
 * It handles both server-side rendering (with synchronous route matching) and client-side
 * hydration (with browser history).
 *
 * @param options - Configuration for the TanStack Router app
 * @param deps - TanStack Router dependencies (RouterProvider, createMemoryHistory, createBrowserHistory)
 * @returns A render function compatible with ReactOnRails.register()
 *
 * @example
 * ```typescript
 * import { createTanStackRouterRenderFunction } from 'react-on-rails/tanstack-router';
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
        'react-on-rails/tanstack-router: railsContext is required. ' +
          'Ensure the component is rendered via react_component helper.',
      );
    }

    if (railsContext.serverSide) {
      const { appElement, dehydratedState } = serverRenderTanStackApp(
        options,
        props,
        railsContext as RailsContext & { serverSide: true },
        RouterProvider,
        createMemoryHistory,
      );

      // Return as serverRenderHash so we can pass dehydrated state into client props.
      return {
        renderedHtml: appElement,
        clientProps: {
          __tanstackRouterDehydratedState: dehydratedState,
        },
      } satisfies ServerRenderResult;
    }

    // Client-side: return a ReactElement that React on Rails will hydrate/render.
    return clientHydrateTanStackApp(
      options,
      props,
      railsContext as RailsContext & { serverSide: false },
      RouterProvider,
      createBrowserHistory,
    ) as any;
  };

  // Mark as a render function so React on Rails executes it rather than treating it
  // as a React component.
  renderFn.renderFunction = true as const;

  return renderFn;
}
