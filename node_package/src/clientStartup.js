import ReactDOM from 'react-dom';

import createReactElement from './createReactElement';
import handleError from './handleError';
import isRouterResult from './isRouterResult';

function debugTurbolinks(...msg) {
  if (!window) {
    return;
  }

  if (ReactOnRails.option('traceTurbolinks')) {
    console.log('TURBO:', ...msg);
  }
}

function turbolinksInstalled() {
  return (typeof Turbolinks !== 'undefined');
}

function forEachComponent(fn, railsContext) {
  const reactOnRailsComponentClassName = `${ReactOnRails.option('domPrefix')}-component`;
  forEach(fn, reactOnRailsComponentClassName, railsContext);
}

function forEachStore(railsContext) {
  const reactOnRailsStoreClassName = `${ReactOnRails.option('domPrefix')}-store`;
  forEach(initializeStore, reactOnRailsStoreClassName, railsContext);
}

function forEach(fn, className, railsContext) {
  const els = document.getElementsByClassName(className);
  for (let i = 0; i < els.length; i++) {
    fn(els[i], railsContext);
  }
}

function turbolinksVersion5() {
  return (typeof Turbolinks.controller !== 'undefined');
}

function initializeStore(el, railsContext) {
  const name = el.getAttribute('data-store-name');
  const props = JSON.parse(el.getAttribute('data-props'));
  const storeGenerator = ReactOnRails.getStoreGenerator(name);
  const store = storeGenerator(props, railsContext);
  ReactOnRails.setStore(name, store);
}

/**
 * Used for client rendering by ReactOnRails
 * @param el
 */
function render(el, railsContext) {
  const name = el.getAttribute('data-component-name');
  const domNodeId = el.getAttribute('data-dom-id');
  const props = JSON.parse(el.getAttribute('data-props'));
  const trace = JSON.parse(el.getAttribute('data-trace'));

  try {
    const domNode = document.getElementById(domNodeId);
    if (domNode) {
      const reactElementOrRouterResult = createReactElement({
        name,
        props,
        domNodeId,
        trace,
        railsContext
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
    handleError({
      e,
      name,
      serverSide: false,
    });
  }
}

function parseRailsContext() {
  const contextId = `${ReactOnRails.option('domPrefix')}-context`;
  const el = document.getElementById(contextId);
  if (el) {
    return JSON.parse(el.getAttribute('data-rails-context'));
  } else {
    return null;
  }
}

function reactOnRailsPageLoaded() {
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

export default function clientStartup(context) {
  const document = context.document;

  // Check if server rendering
  if (!document) {
    return;
  }

  // Tried with a file local variable, but the install handler gets called twice.
  if (context.__REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__) {
    return;
  }

  context.__REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__ = // eslint-disable-line no-param-reassign
    true;

  debugTurbolinks('Adding DOMContentLoaded event to install event listeners.');

  document.addEventListener('DOMContentLoaded', () => {
    // Install listeners when running on the client (browser).
    // We must do this check for turbolinks AFTER the document is loaded because we load the
    // Webpack bundles first.

    if (!turbolinksInstalled()) {
      debugTurbolinks(
        'NOT USING TURBOLINKS: DOMContentLoaded event, calling reactOnRailsPageLoaded'
      );
      reactOnRailsPageLoaded();
    } else {
      if (turbolinksVersion5()) {
        debugTurbolinks(
          'USING TURBOLINKS 5: document added event listeners turbolinks:before-cache and ' +
          'turbolinks:load.'
        );
        document.addEventListener('turbolinks:before-cache', reactOnRailsPageUnloaded);
        document.addEventListener('turbolinks:load', reactOnRailsPageLoaded);
      } else {
        debugTurbolinks(
          'USING TURBOLINKS 2: document added event listeners page:before-unload and ' +
          'page:change.');
        document.addEventListener('page:before-unload', reactOnRailsPageUnloaded);
        document.addEventListener('page:change', reactOnRailsPageLoaded);
      }
    }
  });
}
