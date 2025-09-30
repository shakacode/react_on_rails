import type { RegisteredComponent, ReactComponentOrRenderFunction } from './types/index.ts';
declare const _default: {
  /**
   * @param components { component1: component1, component2: component2, etc. }
   */
  register(components: Record<string, ReactComponentOrRenderFunction>): void;
  /**
   * @param name
   * @returns { name, component, renderFunction, isRenderer }
   */
  get(name: string): RegisteredComponent;
  /**
   * Get a Map containing all registered components. Useful for debugging.
   * @returns Map where key is the component name and values are the
   * { name, component, renderFunction, isRenderer}
   */
  components(): Map<string, RegisteredComponent>;
  /**
   * Pro-only method that waits for component registration
   * @param _name Component name to wait for
   * @throws Always throws error indicating pro package is required
   */
  getOrWaitForComponent(_name: string): never;
  /**
   * Clear all registered components (for testing purposes)
   * @private
   */
  clear(): void;
};
export default _default;
//# sourceMappingURL=ComponentRegistry.d.ts.map
