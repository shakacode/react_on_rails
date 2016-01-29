import clientStartup from './clientStartup';
import handleError from './handleError';
import ComponentStore from './ComponentStore';
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

  option(key) {
    return this._options[key];
  },

  /**
   * Main entry point to using the react-on-rails npm package. This is how Rails will be able to
   * find you components for rendering.
   * @param components (key is component name, value is component)
   */
  register(components) {
    ComponentStore.register(components);
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
    return ComponentStore.get(name);
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
    return ComponentStore.components();
  },

  resetOptions() {
    this._options = Object.assign({}, DEFAULT_OPTIONS);
  },
};

ReactOnRails.resetOptions();

clientStartup(ctx);

export default ctx.ReactOnRails;
