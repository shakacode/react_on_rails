import ReactOnRails from '../ReactOnRails.client.ts';
import { ReactComponent } from '../types/index.ts';

/**
 * Registers React Server Components (RSC) with React on Rails for both server and RSC bundles.
 * Currently, this function behaves identically to ReactOnRails.register, but is introduced to enable
 * future RSC-specific functionality without breaking changes.
 *
 * Future behavior will differ based on bundle type:
 *
 * RSC Bundle:
 * - Components are registered as any other component by adding the component to the ComponentRegistry
 *
 * Server Bundle:
 * - It works like the function defined at `registerServerComponent/client`
 * - The function itself is not added to the ComponentRegistry
 * - Instead, a RSCServerRoot component is added to the ComponentRegistry
 * - This RSCServerRoot component will use the pre-generated RSC payloads from the RSC bundle to
 *   build the rendering tree of the server component instead of rendering it again
 *
 * This functionality is added now without real implementation to avoid breaking changes in the future.
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
  if (ReactOnRails.isRSCBundle) {
    return ReactOnRails.register(components);
  }
  ReactOnRails.registerServerComponentReferences(...Object.keys(components));
};

export default registerServerComponent;
