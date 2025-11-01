import { ReactComponent } from '../../types/index.ts';
/**
 * Registers React Server Components for use in server bundles.
 *
 * This function:
 * 1. Takes server component implementations
 * 2. Wraps each component with RSCRoute using WrapServerComponentRenderer
 * 3. Registers the wrapped components with ReactOnRails
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
declare const registerServerComponent: (components: Record<string, ReactComponent>) => void;
export default registerServerComponent;
