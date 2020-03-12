import ReactDOM from 'react-dom';
import type { Component } from 'react';
import type { RailsContext } from './types/index';

import createReactElement from './createReactElement';
import isRouterResult from './isCreateReactElementResultNonReactComponent';

declare global {
  interface Window {
      ReactOnRails: any;
      __REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__?: boolean;
  }
  namespace NodeJS {
    interface Global {
        ReactOnRails: any;
    }
  }
  namespace Turbolinks {
    interface TurbolinksStatic {
      controller?: any;
    }
  }
}

declare const ReactOnRails: any;

const REACT_ON_RAILS_STORE_ATTRIBUTE = 'data-js-react-on-rails-store';

function findContext(): Window | NodeJS.Global {
  if (typeof window.ReactOnRails !== 'undefined') {
    return window;
  } else if (typeof ReactOnRails !== 'undefined') {
    return global;
  }

  throw new Error(`\
ReactOnRails is undefined in both global and window namespaces.
  `);
}

function debugTurbolinks(...msg: string[]): void {
  if (!window) {
    return;
  }

  const context = findContext();
  if (context.ReactOnRails.option('traceTurbolinks')) {
    console.log('TURBO:', ...msg);
  }
}

function turbolinksInstalled(): boolean {
  return (typeof Turbolinks !== 'undefined');
}

function forEach(fn: Function, className: string, railsContext: RailsContext): void {
  const els = document.getElementsByClassName(className);
  for (let i = 0; i < els.length; i += 1) {
    fn(els[i], railsContext);
  }
}

function forEachByAttribute(fn: Function, attributeName: string, railsContext: RailsContext): void {
  const els = document.querySelectorAll(`[${attributeName}]`);
  for (let i = 0; i < els.length; i += 1) {
    fn(els[i], railsContext);
  }
}

function forEachComponent(fn: Function, railsContext: RailsContext): void {
  forEach(fn, 'js-react-on-rails-component', railsContext);
}

function initializeStore(el: HTMLElement, railsContext: RailsContext): void {
  const context = findContext();
  const name = el.getAttribute(REACT_ON_RAILS_STORE_ATTRIBUTE);
  const props = JSON.parse(el.textContent);
  const storeGenerator = context.ReactOnRails.getStoreGenerator(name);
  const store = storeGenerator(props, railsContext);
  context.ReactOnRails.setStore(name, store);
}

function forEachStore(railsContext: RailsContext): void {
  forEachByAttribute(initializeStore, REACT_ON_RAILS_STORE_ATTRIBUTE, railsContext);
}

function turbolinksVersion5(): boolean {
  return (typeof Turbolinks.controller !== 'undefined');
}

function turbolinksSupported(): boolean {
  return Turbolinks.supported;
}

function delegateToRenderer(
  componentObj: Component,
  props: Object,
  railsContext: RailsContext,
  domNodeId: string,
  trace: string) {
  const { name, component, isRenderer } = componentObj;

  if (isRenderer) {
    if (trace) {
      console.log(`\
DELEGATING TO RENDERER ${name} for dom node with id: ${domNodeId} with props, railsContext:`,
      props, railsContext);
    }

    component(props, railsContext, domNodeId);
    return true;
  }

  return false;
}

function domNodeIdForEl(el: HTMLElement): string {
  return el.getAttribute('data-dom-id');
}

/**
 * Used for client rendering by ReactOnRails. Either calls ReactDOM.hydrate, ReactDOM.render, or
 * delegates to a renderer registered by the user.
 * @param el
 */
function render(el: HTMLElement, railsContext: RailsContext): Component {
  const context = findContext();
  // This must match lib/react_on_rails/helper.rb
  const name = el.getAttribute('data-component-name');
  const domNodeId = domNodeIdForEl(el);
  const props = JSON.parse(el.textContent);
  const trace = el.getAttribute('data-trace');

  try {
    const domNode = document.getElementById(domNodeId);
    if (domNode) {
      const componentObj = context.ReactOnRails.getComponent(name);
      if (delegateToRenderer(componentObj, props, railsContext, domNodeId, trace)) {
        return;
      }

      // Hydrate if available and was server rendered
      const shouldHydrate = !!ReactDOM.hydrate && !!domNode.innerHTML;

      const reactElementOrRouterResult = createReactElement({
        componentObj,
        props,
        domNodeId,
        trace,
        railsContext,
        shouldHydrate,
      });

      if (isRouterResult(reactElementOrRouterResult)) {
        throw new Error(`\
You returned a server side type of react-router error: ${JSON.stringify(reactElementOrRouterResult)}
You should return a React.Component always for the client side entry point.`);
      } else if (shouldHydrate) {
        ReactDOM.hydrate(reactElementOrRouterResult, domNode);
      } else {
        ReactDOM.render(reactElementOrRouterResult, domNode);
      }
    }
  } catch (e) {
    e.message = `ReactOnRails encountered an error while rendering component: ${name}.\n` +
      `Original message: ${e.message}`;
    throw e;
  }
}

function parseRailsContext(): RailsContext {
  const el = document.getElementById('js-react-on-rails-context');
  if (el) {
    return JSON.parse(el.textContent);
  }

  return null;
}

export function reactOnRailsPageLoaded(): void {
  debugTurbolinks('reactOnRailsPageLoaded');

  const railsContext = parseRailsContext();
  forEachStore(railsContext);
  forEachComponent(render, railsContext);
}

function unmount(el: HTMLElement): void {
  const domNodeId = domNodeIdForEl(el);
  const domNode = document.getElementById(domNodeId);
  try {
    ReactDOM.unmountComponentAtNode(domNode);
  } catch (e) {
    console.info(`Caught error calling unmountComponentAtNode: ${e.message} for domNode`,
      domNode, e);
  }
}

function reactOnRailsPageUnloaded(): void {
  debugTurbolinks('reactOnRailsPageUnloaded');
  forEachComponent(unmount, this);
}

function renderInit(): void {
  // Install listeners when running on the client (browser).
  // We must do this check for turbolinks AFTER the document is loaded because we load the
  // Webpack bundles first.
  if (!turbolinksInstalled() || !turbolinksSupported()) {
    debugTurbolinks('NOT USING TURBOLINKS: calling reactOnRailsPageLoaded');
    reactOnRailsPageLoaded();
    return;
  }

  if (turbolinksVersion5()) {
    debugTurbolinks(
      'USING TURBOLINKS 5: document added event listeners ' +
      'turbolinks:before-render and turbolinks:render.');
    document.addEventListener('turbolinks:before-render', reactOnRailsPageUnloaded);
    document.addEventListener('turbolinks:render', reactOnRailsPageLoaded);
    reactOnRailsPageLoaded();
  } else {
    debugTurbolinks(
      'USING TURBOLINKS 2: document added event listeners page:before-unload and ' +
      'page:change.');
    document.addEventListener('page:before-unload', reactOnRailsPageUnloaded);
    document.addEventListener('page:change', reactOnRailsPageLoaded);
  }
}

function isWindow (context: Window | NodeJS.Global): context is Window {
  return (context as Window).document !== undefined;
}

export function clientStartup(context: Window | NodeJS.Global): void {
  // Check if server rendering
  if (!isWindow(context)) {
    return;
  }
  const { document } = context;

  // Tried with a file local variable, but the install handler gets called twice.
  // eslint-disable-next-line no-underscore-dangle
  if (context.__REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__) {
    return;
  }

  // eslint-disable-next-line no-underscore-dangle, no-param-reassign
  context.__REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__ = true;

  debugTurbolinks('Adding DOMContentLoaded event to install event listeners.');

  if (document.readyState === 'complete') {
    window.setTimeout(renderInit);
  } else {
    document.addEventListener('DOMContentLoaded', renderInit);
  }
}
