import ReactOnRails from '../ReactOnRails.client.ts';
import { ReactComponent, RenderFunction } from '../types/index.ts';

/**
 * Registers React Server Components (RSC) with React on Rails for the RSC bundle.
 *
 * This function handles the registration of components in the RSC bundle context,
 * where components are registered directly into the ComponentRegistry without any
 * additional wrapping. This is different from the server bundle registration,
 * which wraps components with RSCServerRoot.
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
const registerServerComponent = (components: { [id: string]: ReactComponent | RenderFunction }) =>
  ReactOnRails.register(components);

export default registerServerComponent;
