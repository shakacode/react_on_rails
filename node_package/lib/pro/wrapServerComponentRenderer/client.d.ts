import { ReactComponentOrRenderFunction, RenderFunction } from '../../types/index.ts';
/**
 * Wraps a client component with the necessary RSC context and handling for client-side operations.
 *
 * This higher-order function:
 * 1. Creates an RSCProvider with client-specific implementation of getReactServerComponent
 * 2. Handles DOM hydration or rendering operations
 * 3. Ensures Suspense boundaries are properly set up for async rendering
 *
 * Use this version specifically for client bundle registration.
 *
 * @param componentOrRenderFunction - Client component or render function to wrap
 * @returns A render function that handles client-side RSC operations and DOM hydration that should be registered with ReactOnRails.register
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
