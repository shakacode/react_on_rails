import clientStartup from './clientStartup';
import handleError from './handleError';
import ComponentRegistry from './ComponentRegistry';
import StoreRegistry from './StoreRegistry';
import serverRenderReactComponent from './serverRenderReactComponent';
import buildConsoleReplay from './buildConsoleReplay';
import createReactElement from './createReactElement';
import ReactDOM from 'react-dom';
import context from './context';

const ctx = context();

const DEFAULT_OPTIONS = {
  traceTurbolinks: false,
};

ctx.ReactOnRails = {
  /**
   * Set options for ReactOnRails, typically before you call ReactOnRails.register
   * Available Options:
   * `traceTurbolinks: true|false Gives you debugging messages on Turbolinks events
   */
  setOptions(options) {
    if (options.hasOwnProperty('traceTurbolinks')) {
      this._options.traceTurbolinks = options.traceTurbolinks;
      delete options.traceTurbolinks;
    }

    if (Object.keys(options).length > 0) {
      throw new Error('Invalid options passed to ReactOnRails.options: ', JSON.stringify(options));
    }
  },

  /**
   * Main entry point to using the react-on-rails npm package. This is how Rails will be able to
   * find you components for rendering.
   * @param components (key is component name, value is component)
   */
  register(components) {
    ComponentRegistry.register(components);
  },

  /**
   * Allows registration of store generators to be used by multiple react components on one Rails view.
   * store generators are functions that take one arg, props, and return a store. Note that the
   * setStore API is different in tha it's the actual store hydrated with props.
   * @param stores (key is store name, value is the store generator)
   */
  registerStore(stores) {
    StoreRegistry.register(stores);
  },

  /**
   * Allows retrieval of the store by name. This store will be hydrated by any
   * Rails form props.
   * @param name
   * @returns Redux Store, possibly hydrated
   */
  getStore(name) {
    return StoreRegistry.getStore(name);
  },

  ////////////////////////////////////////////////////////////////////////////////
  // INTERNALLY USED APIs
  ////////////////////////////////////////////////////////////////////////////////

  /**
   * Retrieve an option by key.
   * @param key
   * @returns option value
   */
  option(key) {
    return this._options[key];
  },

  /**
   * Allows retrieval of the store generator by name. This is used internally by ReactOnRails after
   * a rails form loads to prepare stores.
   * @param name
   * @returns Redux Store generator function
   */
  getStoreGenerator(name) {
    return StoreRegistry.getStoreGenerator(name);
  },

  /**
   * Allows saving the store populated by Rails form props. Used internally by ReactOnRails.
   * @param name
   * @returns Redux Store, possibly hydrated
   */
  setStore(name, store) {
    return StoreRegistry.setStore(name, store);
  },

  /**
   * ReactOnRails.render("HelloWorldApp", {name: "Stranger"}, 'app');
   *
   * Does this:
   *   ReactDOM.render(React.createElement(HelloWorldApp, {name: "Stranger"}),
   *     document.getElementById('app'))
   *
   * @param name Name of your registered component
   * @param props Props to pass to your component
   * @param domNodeId
   * @returns {virtualDomElement} Reference to your component's backing instance
   */
  render(name, props, domNodeId) {
    const reactElement = createReactElement({ name, props, domNodeId });
    return ReactDOM.render(reactElement, document.getElementById(domNodeId));
  },

  /**
   * Get the component that you registered
   * @param name
   * @returns {name, component, generatorFunction}
   */
  getComponent(name) {
    return ComponentRegistry.get(name);
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

  /**
   * Get an Object containing all registered components. Useful for debugging.
   * @returns {*}
   */
  registeredComponents() {
    return ComponentRegistry.components();
  },

  /**
   * Get an Object containing all registered store generators. Useful for debugging.
   * @returns {*}
   */
  storeGenerators() {
    return StoreRegistry.storeGenerators();
  },

  /**
   * Get an Object containing all hydrated stores. Useful for debugging.
   * @returns {*}
   */
  stores() {
    return StoreRegistry.stores();
  },

  resetOptions() {
    this._options = Object.assign({}, DEFAULT_OPTIONS);
  },
};

ReactOnRails.resetOptions();

clientStartup(ctx);

export default ctx.ReactOnRails;
