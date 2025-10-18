import type { RenderFunction, ReactComponentOrRenderFunction } from '../../types/index.ts';
/**
 * Wraps a client component with the necessary RSC context and handling for server-side operations.
 *
 * This higher-order function:
 * 1. Creates an RSCProvider with server-specific implementation of getReactServerComponent
 * 2. Provides a render function that returns React elements for SSR
 * 3. Ensures Suspense boundaries are properly set up for async rendering
 *
 * Use this version specifically for server bundle registration.
 *
 * @param componentOrRenderFunction - Client component or render function to wrap
 * @returns A render function that produces React elements for server-side rendering that should be registered with ReactOnRails.register
 *
 * @example
 * ```tsx
 * const WrappedComponent = WrapServerComponentRenderer(ClientComponent);
 * ReactOnRails.register({ ClientComponent: WrappedComponent });
 * ```
 */
declare const wrapServerComponentRenderer: (
  componentOrRenderFunction: ReactComponentOrRenderFunction,
) => RenderFunction;
export default wrapServerComponentRenderer;
