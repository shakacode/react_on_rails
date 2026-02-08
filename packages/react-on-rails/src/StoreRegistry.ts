import type { Store, StoreGenerator } from './types/index.ts';

const registeredStoreGenerators = new Map<string, StoreGenerator>();
const hydratedStores = new Map<string, Store>();

export default {
  /**
   * Register a store generator, a function that takes props and returns a store.
   * @param storeGenerators { name1: storeGenerator1, name2: storeGenerator2 }
   */
  register(storeGenerators: Record<string, StoreGenerator>): void {
    Object.keys(storeGenerators).forEach((name) => {
      const store = storeGenerators[name];
      if (!store) {
        throw new Error(
          'Called ReactOnRails.registerStores with a null or undefined as a value ' +
            `for the store generator with key ${name}.`,
        );
      }

      const existing = registeredStoreGenerators.get(name);
      if (existing && existing !== store) {
        console.error(
          `ReactOnRails: Store "${name}" was registered with a different store generator than previously. ` +
            'This is likely a bug — ensure each store has a unique registration name.',
        );
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
      const msg = `There are no stores hydrated and you are requesting the store ${name}.
This can happen if you are server rendering and either:
1. You do not call redux_store near the top of your controller action's view (not the layout)
   and before any call to react_component.
2. You do not render redux_store_hydration_data anywhere on your page.`;
      throw new Error(msg);
    }

    if (throwIfMissing) {
      console.log('storeKeys', storeKeys);
      throw new Error(
        `Could not find hydrated store with name '${name}'. ` +
          `Hydrated store names include [${storeKeys}].`,
      );
    }

    return undefined;
  },

  /**
   * Internally used function to get the store creator that was passed to `register`.
   * @param name
   * @returns storeCreator with given name
   */
  getStoreGenerator(name: string): StoreGenerator {
    const registeredStoreGenerator = registeredStoreGenerators.get(name);
    if (registeredStoreGenerator) {
      return registeredStoreGenerator;
    }

    const storeKeys = Array.from(registeredStoreGenerators.keys()).join(', ');
    throw new Error(
      `Could not find store registered with name '${name}'. Registered store ` +
        `names include [ ${storeKeys} ]. Maybe you forgot to register the store?`,
    );
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

  /**
   * Get a store by name, or wait for it to be registered.
   * This is a Pro-only feature that requires React on Rails Pro.
   * @param name
   * @throws Error indicating this is a Pro-only feature
   */
  getOrWaitForStore(name: string): never {
    throw new Error(
      `getOrWaitForStore('${name}') is only available with React on Rails Pro. ` +
        'Please upgrade to React on Rails Pro or use the synchronous getStore() method instead. ' +
        'See https://www.shakacode.com/react-on-rails-pro/ for more information.',
    );
  },

  /**
   * Get a store generator by name, or wait for it to be registered.
   * This is a Pro-only feature that requires React on Rails Pro.
   * @param name
   * @throws Error indicating this is a Pro-only feature
   */
  getOrWaitForStoreGenerator(name: string): never {
    throw new Error(
      `getOrWaitForStoreGenerator('${name}') is only available with React on Rails Pro. ` +
        'Please upgrade to React on Rails Pro or use the synchronous getStoreGenerator() method instead. ' +
        'See https://www.shakacode.com/react-on-rails-pro/ for more information.',
    );
  },
};
