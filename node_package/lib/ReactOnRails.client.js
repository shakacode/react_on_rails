import * as ClientStartup from './clientStartup.js';
import { renderOrHydrateComponent, hydrateStore } from './pro/ClientSideRenderer.js';
import * as ComponentRegistry from './pro/ComponentRegistry.js';
import * as StoreRegistry from './pro/StoreRegistry.js';
import buildConsoleReplay from './buildConsoleReplay.js';
import createReactOutput from './createReactOutput.js';
import * as Authenticity from './Authenticity.js';
import reactHydrateOrRender from './reactHydrateOrRender.js';

if (globalThis.ReactOnRails !== undefined) {
  throw new Error(`\
The ReactOnRails value exists in the ${globalThis} scope, it may not be safe to overwrite it.
This could be caused by setting Webpack's optimization.runtimeChunk to "true" or "multiple," rather than "single."
Check your Webpack configuration. Read more at https://github.com/shakacode/react_on_rails/issues/1558.`);
}
const DEFAULT_OPTIONS = {
  traceTurbolinks: false,
  turbo: false,
  debugMode: false,
  logComponentRegistration: false,
};
globalThis.ReactOnRails = {
  options: {},
  register(components) {
    if (this.options.debugMode || this.options.logComponentRegistration) {
      const startTime = performance.now();
      const componentNames = Object.keys(components);
      console.log(
        `[ReactOnRails] Registering ${componentNames.length} component(s): ${componentNames.join(', ')}`,
      );
      ComponentRegistry.register(components);
      const endTime = performance.now();
      console.log(`[ReactOnRails] Component registration completed in ${(endTime - startTime).toFixed(2)}ms`);
      // Log individual component details if in full debug mode
      if (this.options.debugMode) {
        componentNames.forEach((name) => {
          const component = components[name];
          const size = component.toString().length;
          console.log(`[ReactOnRails] ✅ Registered: ${name} (~${(size / 1024).toFixed(1)}kb)`);
        });
      }
    } else {
      ComponentRegistry.register(components);
    }
  },
  registerStore(stores) {
    this.registerStoreGenerators(stores);
  },
  registerStoreGenerators(storeGenerators) {
    if (!storeGenerators) {
      throw new Error(
        'Called ReactOnRails.registerStoreGenerators with a null or undefined, rather than ' +
          'an Object with keys being the store names and the values are the store generators.',
      );
    }
    StoreRegistry.register(storeGenerators);
  },
  getStore(name, throwIfMissing = true) {
    return StoreRegistry.getStore(name, throwIfMissing);
  },
  getOrWaitForStore(name) {
    return StoreRegistry.getOrWaitForStore(name);
  },
  getOrWaitForStoreGenerator(name) {
    return StoreRegistry.getOrWaitForStoreGenerator(name);
  },
  reactHydrateOrRender(domNode, reactElement, hydrate) {
    return reactHydrateOrRender(domNode, reactElement, hydrate);
  },
  setOptions(newOptions) {
    if (typeof newOptions.traceTurbolinks !== 'undefined') {
      this.options.traceTurbolinks = newOptions.traceTurbolinks;
      // eslint-disable-next-line no-param-reassign
      delete newOptions.traceTurbolinks;
    }
    if (typeof newOptions.turbo !== 'undefined') {
      this.options.turbo = newOptions.turbo;
      // eslint-disable-next-line no-param-reassign
      delete newOptions.turbo;
    }
    if (typeof newOptions.debugMode !== 'undefined') {
      this.options.debugMode = newOptions.debugMode;
      if (newOptions.debugMode) {
        console.log('[ReactOnRails] Debug mode enabled');
      }
      // eslint-disable-next-line no-param-reassign
      delete newOptions.debugMode;
    }
    if (typeof newOptions.logComponentRegistration !== 'undefined') {
      this.options.logComponentRegistration = newOptions.logComponentRegistration;
      if (newOptions.logComponentRegistration) {
        console.log('[ReactOnRails] Component registration logging enabled');
      }
      // eslint-disable-next-line no-param-reassign
      delete newOptions.logComponentRegistration;
    }
    if (Object.keys(newOptions).length > 0) {
      throw new Error(`Invalid options passed to ReactOnRails.options: ${JSON.stringify(newOptions)}`);
    }
  },
  reactOnRailsPageLoaded() {
    return ClientStartup.reactOnRailsPageLoaded();
  },
  reactOnRailsComponentLoaded(domId) {
    return renderOrHydrateComponent(domId);
  },
  reactOnRailsStoreLoaded(storeName) {
    return hydrateStore(storeName);
  },
  authenticityToken() {
    return Authenticity.authenticityToken();
  },
  authenticityHeaders(otherHeaders = {}) {
    return Authenticity.authenticityHeaders(otherHeaders);
  },
  // /////////////////////////////////////////////////////////////////////////////
  // INTERNALLY USED APIs
  // /////////////////////////////////////////////////////////////////////////////
  option(key) {
    return this.options[key];
  },
  getStoreGenerator(name) {
    return StoreRegistry.getStoreGenerator(name);
  },
  setStore(name, store) {
    StoreRegistry.setStore(name, store);
  },
  clearHydratedStores() {
    StoreRegistry.clearHydratedStores();
  },
  render(name, props, domNodeId, hydrate) {
    const componentObj = ComponentRegistry.get(name);
    const reactElement = createReactOutput({ componentObj, props, domNodeId });
    return reactHydrateOrRender(document.getElementById(domNodeId), reactElement, hydrate);
  },
  getComponent(name) {
    return ComponentRegistry.get(name);
  },
  getOrWaitForComponent(name) {
    return ComponentRegistry.getOrWaitForComponent(name);
  },
  serverRenderReactComponent() {
    throw new Error(
      'serverRenderReactComponent is not available in "react-on-rails/client". Import "react-on-rails" server-side.',
    );
  },
  streamServerRenderedReactComponent() {
    throw new Error(
      'streamServerRenderedReactComponent is only supported when using a bundle built for Node.js environments',
    );
  },
  serverRenderRSCReactComponent() {
    throw new Error('serverRenderRSCReactComponent is supported in RSC bundle only.');
  },
  handleError() {
    throw new Error(
      'handleError is not available in "react-on-rails/client". Import "react-on-rails" server-side.',
    );
  },
  buildConsoleReplay() {
    return buildConsoleReplay();
  },
  registeredComponents() {
    return ComponentRegistry.components();
  },
  storeGenerators() {
    return StoreRegistry.storeGenerators();
  },
  stores() {
    return StoreRegistry.stores();
  },
  resetOptions() {
    this.options = { ...DEFAULT_OPTIONS };
  },
  isRSCBundle: false,
};
globalThis.ReactOnRails.resetOptions();
ClientStartup.clientStartup();
export * from './types/index.js';
export default globalThis.ReactOnRails;
