// key = name used by react_on_rails to identify the store
// value = redux store creator, which is a function that takes props and returns a store
import context from './context';
const _storeGenerators = new Map();
const _stores = new Map();

export default {
  /**
   * @param stores { name: component }
   */
  register(stores) {
    Object.keys(stores).forEach(name => {
      if (_storeGenerators.has(name)) {
        console.warn('Called registerStore for store that is already registered', name);
      }

      const store = stores[name];
      _storeGenerators.set(name, store);
    });
  },

  /**
   * @param name
   * @returns storeCreator with given name
   */
  getStoreGenerator(name) {
    if (_storeGenerators.has(name)) {
      return _storeGenerators.get(name);
    } else {
      throw new Error(`Could not find store registered with name ${name}`);
    }
  },

  /**
   * @param name
   * @returns storeCreator with given name
   */
  getStore(name) {
    if (_stores.has(name)) {
      return _stores.get(name);
    } else {
      throw new Error(`Could not find store with name ${name}`);
    }
  },

  /**
   * @param name
   * @param store (not the storeGenerator, but the hydrated store)
   */
  setStore(name, store) {
    _stores.set(name, store);
  },

  /**
   * Get an Map containing all registered stores. Useful for debugging.
   * @returns Map where key is the component name and values are the
   * { name, component, generatorFunction}
   */
  stores() {
    return _storeGenerators;
  },
};







/*
1. Finish up the JS code
2. setup up the creation of HTML props for stores
3. Complete clients side views, including integration tests
4. Do server rendering.

  */
