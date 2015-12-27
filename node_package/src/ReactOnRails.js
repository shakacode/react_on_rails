import clientStartup from './clientStartup';
import handleError from './handleError';
import ComponentStore from './ComponentStore';
import serverRenderReactComponent from './serverRenderReactComponent';
import buildConsoleReplay from './buildConsoleReplay';

const context = ((typeof window !== 'undefined') && window) ||
  ((typeof global !== 'undefined') && global) || this;

context.ReactOnRails = {
  getComponent(name) {
    return ComponentStore.getComponent(name);
  },

  register(componentName, component, options = {}) {
    ComponentStore.register(componentName, component, options);
  },

  serverRenderReactComponent(options) {
    return serverRenderReactComponent(options);
  },

  // Passing either componentName or jsCode
  handleError(options) {
    return handleError(options);
  },

  buildConsoleReplay() {
    return buildConsoleReplay();
  },
};

clientStartup(context);

export default context.ReactOnRails;
