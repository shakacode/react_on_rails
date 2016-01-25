import clientStartup from './clientStartup';
import handleError from './handleError';
import ComponentStore from './ComponentStore';
import serverRenderReactComponent from './serverRenderReactComponent';
import buildConsoleReplay from './buildConsoleReplay';
import createReactElement from './createReactElement';
import ReactDOM from 'react-dom';
import context from './context';

const ctx = context();

ctx.ReactOnRails = {
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
   */
  render(name, props, domNodeId) {
    const reactElement = createReactElement({ name, props, domNodeId });
    ReactDOM.render(reactElement, document.getElementById(domNodeId));
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
};

clientStartup(ctx);

export default ctx.ReactOnRails;
