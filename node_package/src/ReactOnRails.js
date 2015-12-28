import clientStartup from './clientStartup';
import handleError from './handleError';
import ComponentStore from './ComponentStore';
import serverRenderReactComponent from './serverRenderReactComponent';
import buildConsoleReplay from './buildConsoleReplay';

const context =
  ((typeof window !== 'undefined') && window) ||
  ((typeof global !== 'undefined') && global) ||
  this;

context.ReactOnRails = {
  /**
   * Main entry point to using the react-on-rails npm package. This is how Rails will be able to
   * find you components for rendering.
   * @param componentNameOrComponents componentName | components (key is component name)
   * @param component
   * @param options
   * @param options.generatorFunction True if a generator function, which is a function that
   *   returns a React.Component
   */
  register(componentNameOrComponents, component, options = {}) {
    if (typeof componentNameOrComponents === 'string') {
      ComponentStore.register(componentNameOrComponents, component, options);
    } else {
      const components = componentNameOrComponents;
      Object.keys(components).forEach(name => ComponentStore.register(name, components[name]));
    }
  },

  /**
   * Get the component that you registered
   * @param name
   * @returns {name, component, generatorFunction}
   */
  getComponent(name) {
    return ComponentStore.getComponent(name);
  },

  /**
   * Used by server rendering by Rails
   * @param options
   */
  serverRenderReactComponent(options) {
    return serverRenderReactComponent(options);
  },

  /**
   * Used by Rails to catch errors in rendering
   * @param options
   */
  handleError(options) {
    return handleError(options);
  },

  /**
   * Used by Rails server rendering to replay console messages.
   */
  buildConsoleReplay() {
    return buildConsoleReplay();
  },
};

clientStartup(context);

export default context.ReactOnRails;
