import CallbackRegistry from './CallbackRegistry';
import type { Store, StoreGenerator } from './types';

const storeGeneratorRegistry = new CallbackRegistry<StoreGenerator>('store generator');
const hydratedStoreRegistry = new CallbackRegistry<Store>('hydrated store');

export default {
  /**
   * Register a store generator, a function that takes props and returns a store.
   * @param storeGenerators { name1: storeGenerator1, name2: storeGenerator2 }
   */
  register(storeGenerators: { [id: string]: StoreGenerator }): void {
    Object.keys(storeGenerators).forEach((name) => {
      if (storeGeneratorRegistry.has(name)) {
        console.warn('Called registerStore for store that is already registered', name);
      }

      const store = storeGenerators[name];
      if (!store) {
        throw new Error(
          'Called ReactOnRails.registerStores with a null or undefined as a value ' +
            `for the store generator with key ${name}.`,
        );
      }

      storeGeneratorRegistry.set(name, store);
    });
  },

  /**
   * Used by components to get the hydrated store which contains props.
   * @param name
   * @param throwIfMissing Defaults to true. Set to false to have this call return undefined if
   *        there is no store with the given name.
   * @returns Redux Store, possibly hydrated
   */
  getStore(name: string, throwIfMissing = true): Store | undefined {
    try {
      return hydratedStoreRegistry.get(name);
    } catch (error) {
      if (hydratedStoreRegistry.getAll().size === 0) {
        const msg = `There are no stores hydrated and you are requesting the store ${name}.
This can happen if you are server rendering and either:
1. You do not call redux_store near the top of your controller action's view (not the layout)
   and before any call to react_component.
2. You do not render redux_store_hydration_data anywhere on your page.`;
        throw new Error(msg);
      }

      if (throwIfMissing) {
        throw error;
      }
      return undefined;
    }
  },

  /**
   * Internally used function to get the store creator that was passed to `register`.
   * @param name
   * @returns storeCreator with given name
   */
  getStoreGenerator(name: string): StoreGenerator {
    return storeGeneratorRegistry.get(name);
  },

  /**
   * Internally used function to set the hydrated store after a Rails page is loaded.
   * @param name
   * @param store (not the storeGenerator, but the hydrated store)
   */
  setStore(name: string, store: Store): void {
    hydratedStoreRegistry.set(name, store);
  },

  /**
   * Internally used function to completely clear hydratedStores Map.
   */
  clearHydratedStores(): void {
    hydratedStoreRegistry.clear();
  },

  /**
   * Get a Map containing all registered store generators. Useful for debugging.
   * @returns Map where key is the component name and values are the store generators.
   */
  storeGenerators(): Map<string, StoreGenerator> {
    return storeGeneratorRegistry.getAll();
  },

  /**
   * Get a Map containing all hydrated stores. Useful for debugging.
   * @returns Map where key is the component name and values are the hydrated stores.
   */
  stores(): Map<string, Store> {
    return hydratedStoreRegistry.getAll();
  },

  /**
   * Used by components to get the hydrated store, waiting for it to be hydrated if necessary.
   * @param name Name of the store to wait for
   * @returns Promise that resolves with the Store once hydrated
   */
  getOrWaitForStore(name: string): Promise<Store> {
    return hydratedStoreRegistry.getOrWaitForItem(name);
  },

  /**
   * Used by components to get the store generator, waiting for it to be registered if necessary.
   * @param name Name of the store generator to wait for
   * @returns Promise that resolves with the StoreGenerator once registered
   */
  getOrWaitForStoreGenerator(name: string): Promise<StoreGenerator> {
    return storeGeneratorRegistry.getOrWaitForItem(name);
  },
};
