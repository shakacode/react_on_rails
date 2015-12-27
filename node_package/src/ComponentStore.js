const components = {};

export default {
  componentForName(name) {
    if (components[name]) {
      return components[name];
    }

    if (!context[name]) {
      throw new Error(`Could not find component registered with name ${name}`);
    }

    console.warn(
      'WARNING: Global components are deprecated support will be removed from a future version. ' +
      'Use ReactOnRails.registerComponent');
    return context[name];
  },

  registerComponent(componentName, component, options) {
    components[componentName] = component;
  },
};
