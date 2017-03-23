/* global ReactOnRails Turbolinks */

import ReactDOM from 'react-dom';

import createReactElement from './createReactElement';
import isRouterResult from './isCreateReactElementResultNonReactComponent';

const REACT_ON_RAILS_COMPONENT_CLASS_NAME = 'js-react-on-rails-component';
const REACT_ON_RAILS_STORE_CLASS_NAME = 'js-react-on-rails-store';

function findContext() {
  if (typeof window.ReactOnRails !== 'undefined') {
    return window;
  } else if (typeof ReactOnRails !== 'undefined') {
    return global;
  }

  throw new Error(`\
ReactOnRails is undefined in both global and window namespaces.
  `);
}

function debugTurbolinks(...msg) {
  if (!window) {
    return;
  }

  const context = findContext();
  if (context.ReactOnRails.option('traceTurbolinks')) {
    console.log('TURBO:', ...msg);
  }
}

function turbolinksInstalled() {
  return (typeof Turbolinks !== 'undefined');
}

function forEach(fn, className, railsContext) {
  const els = document.getElementsByClassName(className);
  for (let i = 0; i < els.length; i += 1) {
    fn(els[i], railsContext);
  }
}

function forEachComponent(fn, railsContext) {
  forEach(fn, REACT_ON_RAILS_COMPONENT_CLASS_NAME, railsContext);
}

function initializeStore(el, railsContext) {
  const context = findContext();
  const name = el.getAttribute('data-store-name');
  const props = JSON.parse(el.getAttribute('data-props'));
  const storeGenerator = context.ReactOnRails.getStoreGenerator(name);
  const store = storeGenerator(props, railsContext);
  context.ReactOnRails.setStore(name, store);
}

function forEachStore(railsContext) {
  forEach(initializeStore, REACT_ON_RAILS_STORE_CLASS_NAME, railsContext);
}

function turbolinksVersion5() {
  return (typeof Turbolinks.controller !== 'undefined');
}

function turbolinksSupported() {
  return Turbolinks.supported;
}

function delegateToRenderer(componentObj, props, railsContext, domNodeId, trace) {
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

/**
 * Used for client rendering by ReactOnRails. Either calls ReactDOM.render or delegates
 * to a renderer registered by the user.
 * @param el
 */
function render(el, railsContext) {
  const context = findContext();
  const name = el.getAttribute('data-component-name');
  const domNodeId = el.getAttribute('data-dom-id');
  const props = JSON.parse(el.getAttribute('data-props'));
  const trace = JSON.parse(el.getAttribute('data-trace'));

  try {
    const domNode = document.getElementById(domNodeId);
    if (domNode) {
      const componentObj = context.ReactOnRails.getComponent(name);
      if (delegateToRenderer(componentObj, props, railsContext, domNodeId, trace)) {
        return;
      }

      const reactElementOrRouterResult = createReactElement({
        componentObj,
        props,
        domNodeId,
        trace,
        railsContext,
      });

      if (isRouterResult(reactElementOrRouterResult)) {
        throw new Error(`\
You returned a server side type of react-router error: ${JSON.stringify(reactElementOrRouterResult)}
You should return a React.Component always for the client side entry point.`);
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

function parseRailsContext() {
  const el = document.getElementById('js-react-on-rails-context');
  if (el) {
    return JSON.parse(el.getAttribute('data-rails-context'));
  }

  return null;
}

export function reactOnRailsPageLoaded() {
  debugTurbolinks('reactOnRailsPageLoaded');

  const railsContext = parseRailsContext();
  forEachStore(railsContext);
  forEachComponent(render, railsContext);
}

function unmount(el) {
  const domNodeId = el.getAttribute('data-dom-id');
  const domNode = document.getElementById(domNodeId);
  ReactDOM.unmountComponentAtNode(domNode);
}

function reactOnRailsPageUnloaded() {
  debugTurbolinks('reactOnRailsPageUnloaded');
  forEachComponent(unmount);
}

export function clientStartup(context) {
  const document = context.document;

  // Check if server rendering
  if (!document) {
    return;
  }

  // Tried with a file local variable, but the install handler gets called twice.
  // eslint-disable-next-line no-underscore-dangle
  if (context.__REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__) {
    return;
  }

  // eslint-disable-next-line no-underscore-dangle, no-param-reassign
  context.__REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__ = true;

  debugTurbolinks('Adding DOMContentLoaded event to install event listeners.');

  document.addEventListener('DOMContentLoaded', () => {
    // Install listeners when running on the client (browser).
    // We must do this check for turbolinks AFTER the document is loaded because we load the
    // Webpack bundles first.

    if (turbolinksInstalled() && turbolinksSupported()) {
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
    } else {
      debugTurbolinks(
        'NOT USING TURBOLINKS: DOMContentLoaded event, calling reactOnRailsPageLoaded',
      );
      reactOnRailsPageLoaded();
    }
  });
}
