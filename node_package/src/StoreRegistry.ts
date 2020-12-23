import type { StoreGenerator } from './types';

/* eslint-disable @typescript-eslint/no-explicit-any */
type Store = any;

const registeredStoreGenerators = new Map();
const hydratedStores = new Map();

export default {
  /**
   * Register a store generator, a function that takes props and returns a store.
   * @param storeGenerators { name1: storeGenerator1, name2: storeGenerator2 }
   */
  register(storeGenerators: { [id: string]: Store }): void {
    Object.keys(storeGenerators).forEach(name => {
      if (registeredStoreGenerators.has(name)) {
        console.warn('Called registerStore for store that is already registered', name);
      }

      const store = storeGenerators[name];
      if (!store) {
        throw new Error('Called ReactOnRails.registerStores with a null or undefined as a value ' +
          `for the store generator with key ${name}.`);
      }

      registeredStoreGenerators.set(name, store);
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
    if (hydratedStores.has(name)) {
      return hydratedStores.get(name);
    }

    const storeKeys = Array.from(hydratedStores.keys()).join(', ');

    if (storeKeys.length === 0) {
      const msg =
`There are no stores hydrated and you are requesting the store ${name}.
This can happen if you are server rendering and either:
1. You do not call redux_store near the top of your controller action's view (not the layout)
   and before any call to react_component.
2. You do not render redux_store_hydration_data anywhere on your page.`;
      throw new Error(msg);
    }

    if (throwIfMissing) {
      console.log('storeKeys', storeKeys);
      throw new Error(`Could not find hydrated store with name '${name}'. ` +
        `Hydrated store names include [${storeKeys}].`);
    }

    return undefined;
  },

  /**
   * Internally used function to get the store creator that was passed to `register`.
   * @param name
   * @returns storeCreator with given name
   */
  getStoreGenerator(name: string): StoreGenerator {
    if (registeredStoreGenerators.has(name)) {
      return registeredStoreGenerators.get(name);
    }

    const storeKeys = Array.from(registeredStoreGenerators.keys()).join(', ');
    throw new Error(`Could not find store registered with name '${name}'. Registered store ` +
      `names include [ ${storeKeys} ]. Maybe you forgot to register the store?`);
  },

  /**
   * Internally used function to set the hydrated store after a Rails page is loaded.
   * @param name
   * @param store (not the storeGenerator, but the hydrated store)
   */
  setStore(name: string, store: Store): void {
    hydratedStores.set(name, store);
  },

  /**
   * Internally used function to completely clear hydratedStores Map.
   */
  clearHydratedStores(): void {
    hydratedStores.clear();
  },

  /**
   * Get a Map containing all registered store generators. Useful for debugging.
   * @returns Map where key is the component name and values are the store generators.
   */
  storeGenerators(): Map<string, StoreGenerator> {
    return registeredStoreGenerators;
  },

  /**
   * Get a Map containing all hydrated stores. Useful for debugging.
   * @returns Map where key is the component name and values are the hydrated stores.
   */
  stores(): Map<string, Store> {
    return hydratedStores;
  },
};
