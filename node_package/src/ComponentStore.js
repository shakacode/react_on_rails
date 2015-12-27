
// key = name used by react_on_rails
// value = { name, component, generatorFunction }
const components = new Map();

export default {

  /**
   * @param name
   * @returns { name, component, generatorFunction }
   */
  getComponent(name) {
    if (components.has(name)) {
      return components.get(name);
    }

    if (!context[name]) {
      throw new Error(`Could not find component registered with name ${name}`);
    }

    console.warn(
      'WARNING: Global components are deprecated support will be removed from a future version. ' +
      'Use ReactOnRails.register');
    return { name, component: context[name] };
  },

  /**
   * @param name
   * @param component
   * @param options { generatorFunction: boolean }
   */
  register(name, component, options = {}) {
    components.set(name, { name, component, generatorFunction: options.generatorFunction });
  },
};
