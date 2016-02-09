import ReactDOM from 'react-dom';

import createReactElement from './createReactElement';
import handleError from './handleError';
import isRouterResult from './isRouterResult';

const REACT_ON_RAILS_COMPONENT_CLASS_NAME = 'js-react-on-rails-component';
const REACT_ON_RAILS_STORE_CLASS_NAME = 'js-react-on-rails-store';

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

function forEachComponent(fn) {
  forEach(fn, REACT_ON_RAILS_COMPONENT_CLASS_NAME);
}

function forEachStore(fn) {
  forEach(fn, REACT_ON_RAILS_STORE_CLASS_NAME);
}

function forEach(fn, className) {
  const els = document.getElementsByClassName(className);
  for (let i = 0; i < els.length; i++) {
    fn(els[i]);
  }
}

function initializeStore(el) {
  const name = el.getAttribute('data-store-name');
  const props = JSON.parse(el.getAttribute('data-props'));
  const storeGenerator = ReactOnRails.getStoreGenerator(name);
  const store = storeGenerator(props);
  ReactOnRails.setStore(name, store);
}

/**
 * Used for client rendering by ReactOnRails
 * @param el
 */
function render(el) {
  const name = el.getAttribute('data-component-name');
  const domNodeId = el.getAttribute('data-dom-id');
  const props = JSON.parse(el.getAttribute('data-props'));
  const trace = JSON.parse(el.getAttribute('data-trace'));
  const expectTurboLinks = JSON.parse(el.getAttribute('data-expect-turbo-links'));

  if (!turbolinksInstalled() && expectTurboLinks) {
    console.warn('WARNING: NO TurboLinks detected in JS, but it is in your Gemfile');
  }

  try {
    const domNode = document.getElementById(domNodeId);
    if (domNode) {
      const reactElementOrRouterResult = createReactElement({
        name,
        props,
        domNodeId,
        trace,
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

function reactOnRailsPageLoaded() {
  debugTurbolinks('reactOnRailsPageLoaded');

  forEachStore(initializeStore);
  forEachComponent(render);
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
      debugTurbolinks('NOT USING TURBOLINKS: DOMContentLoaded event, calling reactOnRailsPageLoaded');
      reactOnRailsPageLoaded();
    } else {
      debugTurbolinks('USING TURBOLINKS: document page:before-unload and page:change handlers' +
        ' installed.');
      document.addEventListener('page:before-unload', reactOnRailsPageUnloaded);
      document.addEventListener('page:change', reactOnRailsPageLoaded);
    }
  });
}
