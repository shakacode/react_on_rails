// key = name used by react_on_rails to identify the store
// value = redux store creator, which is a function that takes props and returns a store
import context from './context';
const _storeGenerators = new Map();
const _stores = new Map();

export default {
  /**
   * Register a store generator, a function that takes props and returns a store.
   * @param storeGenerators { name1: storeGenerator1, name2: storeGenerator2 }
   */
  register(storeGenerators) {
    Object.keys(storeGenerators).forEach(name => {
      if (_storeGenerators.has(name)) {
        console.warn('Called registerStore for store that is already registered', name);
      }

      const store = storeGenerators[name];
      if (!store) {
        throw new Error(`Called ReactOnRails.registerStores with a null or undefined as a value ` +
          `for the store generator with key ${name}.`);
      }

      _storeGenerators.set(name, store);
    });
  },

  /**
   * Used by components to get the hydrated store which contains props.
   * @param name
   * @param throwIfMissing Defaults to true. Set to false to have this call return undefined if
   *        there is no store with the given name.
   * @returns Redux Store, possibly hydrated
   */
  getStore(name, throwIfMissing = true) {
    if (_stores.has(name)) {
      return _stores.get(name);
    }

    const storeKeys = Array.from(_stores.keys()).join(', ');

    if (storeKeys.length === 0) {
      const msg = `There are no stores hydrated and you are requesting the store ` +
        `${name}. This can happen if you are server rendering and you do not call ` +
        `redux_store near the top of your controller action's view (not the layout) ` +
        `and before any call to react_component.`;
      throw new Error(msg);
    }

    if (throwIfMissing)  {
      console.log('storeKeys', storeKeys);
      throw new Error(`Could not find hydrated store with name '${name}'. ` +
        `Hydrated store names include [${storeKeys}].`);
    }
  },

  /**
   * Internally used function to get the store creator that was passed to `register`.
   * @param name
   * @returns storeCreator with given name
   */
  getStoreGenerator(name) {
    if (_storeGenerators.has(name)) {
      return _storeGenerators.get(name);
    } else {
      const storeKeys = Array.from(_storeGenerators.keys()).join(', ');
      throw new Error(`Could not find store registered with name '${name}'. Registered store ` +
        `names include [ ${storeKeys} ]. Maybe you forgot to register the store?`);
    }
  },

  /**
   * Internally used function to set the hydrated store after a Rails page is loaded.
   * @param name
   * @param store (not the storeGenerator, but the hydrated store)
   */
  setStore(name, store) {
    _stores.set(name, store);
  },

  /**
   * Get a Map containing all registered store generators. Useful for debugging.
   * @returns Map where key is the component name and values are the store generators.
   */
  storeGenerators() {
    return _storeGenerators;
  },

  /**
   * Get a Map containing all hydrated stores. Useful for debugging.
   * @returns Map where key is the component name and values are the hydrated stores.
   */
  stores() {
    return _stores;
  },
};
