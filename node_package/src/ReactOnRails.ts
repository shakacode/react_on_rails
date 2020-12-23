import ReactDOM from 'react-dom';
import type { ReactElement, Component } from 'react';

import * as ClientStartup from './clientStartup';
import handleError from './handleError';
import ComponentRegistry from './ComponentRegistry';
import StoreRegistry from './StoreRegistry';
import serverRenderReactComponent from './serverRenderReactComponent';
import buildConsoleReplay from './buildConsoleReplay';
import createReactOutput from './createReactOutput';
import Authenticity from './Authenticity';
import context from './context';
import type {
  RegisteredComponent,
  RenderParams,
  ErrorOptions,
  ReactComponentOrRenderFunction,
  AuthenticityHeaders,
  StoreGenerator
} from './types/index';

/* eslint-disable @typescript-eslint/no-explicit-any */
type Store = any;

const ctx = context();

if (ctx === undefined) {
  throw new Error("The context (usually Window or NodeJS's Global) is undefined.");
}

const DEFAULT_OPTIONS = {
  traceTurbolinks: false,
};

ctx.ReactOnRails = {
  options: {},
  /**
   * Main entry point to using the react-on-rails npm package. This is how Rails will be able to
   * find you components for rendering.
   * @param components (key is component name, value is component)
   */
  register(components: { [id: string]: ReactComponentOrRenderFunction }): void {
    ComponentRegistry.register(components);
  },

  /**
   * Allows registration of store generators to be used by multiple react components on one Rails
   * view. store generators are functions that take one arg, props, and return a store. Note that
   * the setStore API is different in that it's the actual store hydrated with props.
   * @param stores (keys are store names, values are the store generators)
   */
  registerStore(stores: { [id: string]: Store }): void {
    if (!stores) {
      throw new Error('Called ReactOnRails.registerStores with a null or undefined, rather than ' +
        'an Object with keys being the store names and the values are the store generators.');
    }

    StoreRegistry.register(stores);
  },

  /**
   * Allows retrieval of the store by name. This store will be hydrated by any Rails form props.
   * Pass optional param throwIfMissing = false if you want to use this call to get back null if the
   * store with name is not registered.
   * @param name
   * @param throwIfMissing Defaults to true. Set to false to have this call return undefined if
   *        there is no store with the given name.
   * @returns Redux Store, possibly hydrated
   */
  getStore(name: string, throwIfMissing = true): Store | undefined {
    return StoreRegistry.getStore(name, throwIfMissing);
  },

  /**
   * Set options for ReactOnRails, typically before you call ReactOnRails.register
   * Available Options:
   * `traceTurbolinks: true|false Gives you debugging messages on Turbolinks events
   */
  setOptions(newOptions: {traceTurbolinks?: boolean}): void {
    if (typeof newOptions.traceTurbolinks !== 'undefined') {
      this.options.traceTurbolinks = newOptions.traceTurbolinks;

      // eslint-disable-next-line no-param-reassign
      delete newOptions.traceTurbolinks;
    }

    if (Object.keys(newOptions).length > 0) {
      throw new Error(
        `Invalid options passed to ReactOnRails.options: ${JSON.stringify(newOptions)}`,
      );
    }
  },

  /**
   * Allow directly calling the page loaded script in case the default events that trigger react
   * rendering are not sufficient, such as when loading JavaScript asynchronously with TurboLinks:
   * More details can be found here:
   * https://github.com/shakacode/react_on_rails/blob/master/docs/additional-reading/turbolinks.md
   */
  reactOnRailsPageLoaded(): void {
    ClientStartup.reactOnRailsPageLoaded();
  },

  /**
   * Returns CSRF authenticity token inserted by Rails csrf_meta_tags
   * @returns String or null
   */

  authenticityToken(): string | null {
    return Authenticity.authenticityToken();
  },

  /**
   * Returns header with csrf authenticity token and XMLHttpRequest
   * @param {*} other headers
   * @returns {*} header
   */

  authenticityHeaders(otherHeaders: { [id: string]: string } = {}): AuthenticityHeaders {
    return Authenticity.authenticityHeaders(otherHeaders);
  },

  // /////////////////////////////////////////////////////////////////////////////
  // INTERNALLY USED APIs
  // /////////////////////////////////////////////////////////////////////////////

  /**
   * Retrieve an option by key.
   * @param key
   * @returns option value
   */
  option(key: string): string | number | boolean | undefined {
    return this.options[key];
  },

  /**
   * Allows retrieval of the store generator by name. This is used internally by ReactOnRails after
   * a rails form loads to prepare stores.
   * @param name
   * @returns Redux Store generator function
   */
  getStoreGenerator(name: string): StoreGenerator {
    return StoreRegistry.getStoreGenerator(name);
  },

  /**
   * Allows saving the store populated by Rails form props. Used internally by ReactOnRails.
   * @param name
   * @returns Redux Store, possibly hydrated
   */
  setStore(name: string, store: Store): void {
    return StoreRegistry.setStore(name, store);
  },

  /**
   * Clears hydratedStores to avoid accidental usage of wrong store hydrated in previous/parallel
   * request.
   */
  clearHydratedStores(): void {
    StoreRegistry.clearHydratedStores();
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
   * @param hydrate Pass truthy to update server rendered html. Default is falsy
   * @returns {virtualDomElement} Reference to your component's backing instance
   */
  render(name: string, props: Record<string, string>, domNodeId: string, hydrate: boolean): void | Element | Component {
    const componentObj = ComponentRegistry.get(name);
    const reactElement = createReactOutput({ componentObj, props, domNodeId });

    const render = hydrate ? ReactDOM.hydrate : ReactDOM.render;
    // eslint-disable-next-line react/no-render-return-value
    return render(reactElement as ReactElement, document.getElementById(domNodeId));
  },

  /**
   * Get the component that you registered
   * @param name
   * @returns {name, component, renderFunction, isRenderer}
   */
  getComponent(name: string): RegisteredComponent {
    return ComponentRegistry.get(name);
  },

  /**
   * Used by server rendering by Rails
   * @param options
   */
  serverRenderReactComponent(options: RenderParams): string {
    return serverRenderReactComponent(options);
  },

  /**
   * Used by Rails to catch errors in rendering
   * @param options
   */
  handleError(options: ErrorOptions): string | undefined {
    return handleError(options);
  },

  /**
   * Used by Rails server rendering to replay console messages.
   */
  buildConsoleReplay(): string {
    return buildConsoleReplay();
  },

  /**
   * Get an Object containing all registered components. Useful for debugging.
   * @returns {*}
   */
  registeredComponents(): Map<string, RegisteredComponent> {
    return ComponentRegistry.components();
  },

  /**
   * Get an Object containing all registered store generators. Useful for debugging.
   * @returns {*}
   */
  storeGenerators(): Map<string, StoreGenerator> {
    return StoreRegistry.storeGenerators();
  },

  /**
   * Get an Object containing all hydrated stores. Useful for debugging.
   * @returns {*}
   */
  stores(): Map<string, Store> {
    return StoreRegistry.stores();
  },

  resetOptions(): void {
    this.options = Object.assign({}, DEFAULT_OPTIONS);
  },
};

ctx.ReactOnRails.resetOptions();

ClientStartup.clientStartup(ctx);

export default ctx.ReactOnRails;
