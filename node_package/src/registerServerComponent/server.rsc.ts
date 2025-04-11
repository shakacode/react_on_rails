import { register } from '../ReactOnRails.client.ts';
import { ReactComponent, RenderFunction } from '../types/index.ts';

/**
 * Registers React Server Components in the RSC bundle.
 *
 * Unlike the client and server implementations, the RSC bundle registration
 * directly registers components without any wrapping. This is because the
 * RSC bundle is responsible for generating the actual RSC payload of server
 * components, not for rendering or hydrating client components.
 *
 * @param components - Object mapping component names to their implementations
 *
 * @example
 * ```js
 * registerServerComponent({
 *   ServerComponent1,
 *   ServerComponent2,
 * });
 * ```
 */
const registerServerComponent = (components: { [id: string]: ReactComponent | RenderFunction }) =>
  register(components);

export default registerServerComponent;
