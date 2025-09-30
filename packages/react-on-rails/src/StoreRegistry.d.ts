import type { Store, StoreGenerator } from './types/index.ts';
declare const _default: {
  /**
   * Register a store generator, a function that takes props and returns a store.
   * @param storeGenerators { name1: storeGenerator1, name2: storeGenerator2 }
   */
  register(storeGenerators: Record<string, StoreGenerator>): void;
  /**
   * Used by components to get the hydrated store which contains props.
   * @param name
   * @param throwIfMissing Defaults to true. Set to false to have this call return undefined if
   *        there is no store with the given name.
   * @returns Redux Store, possibly hydrated
   */
  getStore(name: string, throwIfMissing?: boolean): Store | undefined;
  /**
   * Internally used function to get the store creator that was passed to `register`.
   * @param name
   * @returns storeCreator with given name
   */
  getStoreGenerator(name: string): StoreGenerator;
  /**
   * Internally used function to set the hydrated store after a Rails page is loaded.
   * @param name
   * @param store (not the storeGenerator, but the hydrated store)
   */
  setStore(name: string, store: Store): void;
  /**
   * Internally used function to completely clear hydratedStores Map.
   */
  clearHydratedStores(): void;
  /**
   * Get a Map containing all registered store generators. Useful for debugging.
   * @returns Map where key is the component name and values are the store generators.
   */
  storeGenerators(): Map<string, StoreGenerator>;
  /**
   * Get a Map containing all hydrated stores. Useful for debugging.
   * @returns Map where key is the component name and values are the hydrated stores.
   */
  stores(): Map<string, Store>;
  /**
   * Get a store by name, or wait for it to be registered.
   * This is a Pro-only feature that requires React on Rails Pro.
   * @param name
   * @throws Error indicating this is a Pro-only feature
   */
  getOrWaitForStore(name: string): never;
  /**
   * Get a store generator by name, or wait for it to be registered.
   * This is a Pro-only feature that requires React on Rails Pro.
   * @param name
   * @throws Error indicating this is a Pro-only feature
   */
  getOrWaitForStoreGenerator(name: string): never;
};
export default _default;
//# sourceMappingURL=StoreRegistry.d.ts.map
