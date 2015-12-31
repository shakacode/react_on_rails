// key = name used by react_on_rails
// value = { name, component, generatorFunction: boolean }
import generatorFunction from './generatorFunction';
import context from './context';
const _components = new Map();

export default {
  /**
   * @param components { name: component }
   */
  register(components) {
    Object.keys(components).forEach(name => {
      if (_components.has(name)) {
        console.warn('Called register for component that is already registered', name);
      }

      const component = components[name];
      const isGeneratorFunction = generatorFunction(component);

      _components.set(name, {
        name,
        component,
        generatorFunction: isGeneratorFunction,
      });
    });
  },

  /**
   * @param name
   * @returns { name, component, generatorFunction }
   */
  getComponent(name) {
    const ctx = context();
    if (_components.has(name)) {
      return _components.get(name);
    }

    // Backwards compatability. Remove for v3.0.
    if (!ctx[name]) {
      throw new Error(`Could not find component registered with name ${name}`);
    }

    console.warn(
      'WARNING: Global components are deprecated support will be removed from a future version. ' +
      'Use ReactOnRails.register');
    return { name, component: ctx[name] };
  },

  /**
   * Get an Object containing all registered components. Useful for debugging.
   * @returns {*}
   */
  components() {
    return _components;
  },
};
