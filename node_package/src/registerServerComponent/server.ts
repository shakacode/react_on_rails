import ReactOnRails from '../ReactOnRails.client.ts';
import RSCServerRoot from '../RSCServerRoot.ts';
import { ReactComponent, RenderFunction, RailsContext } from '../types/index.ts';

/**
 * Registers React Server Components (RSC) with React on Rails for the server bundle.
 * 
 * This function wraps each component with RSCServerRoot, which handles the server-side
 * rendering of React Server Components using pre-generated RSC payloads.
 * 
 * The RSCServerRoot component:
 * - Uses pre-generated RSC payloads from the RSC bundle
 * - Builds the rendering tree of the server component
 * - Handles the integration with React's streaming SSR
 *
 * @param components - Object mapping component names to their implementations
 *
 * @example
 * ```js
 * registerServerComponent({
 *   ServerComponent1: ServerComponent1Component,
 *   ServerComponent2: ServerComponent2Component
 * });
 * ```
 */
const registerServerComponent = (components: Record<string, ReactComponent>) => {
  const componentsWrappedInRSCServerRoot: Record<string, RenderFunction> = {};
  for (const [componentName] of Object.entries(components)) {
    componentsWrappedInRSCServerRoot[componentName] = (
      componentProps?: unknown,
      railsContext?: RailsContext,
    ) => RSCServerRoot({ componentName, componentProps }, railsContext);
  }
  return ReactOnRails.register(componentsWrappedInRSCServerRoot);
};

export default registerServerComponent;
