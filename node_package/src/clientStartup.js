import ReactDOM from 'react-dom';

import createReactElement from './createReactElement';
import handleError from './handleError';
import isRouterResult from './isRouterResult';

const REACT_ON_RAILS_COMPONENT_CLASS_NAME = 'js-react-on-rails-component';
const turbolinksInstalled = (typeof Turbolinks !== 'undefined');

function forEachComponent(fn) {
  const els = document.getElementsByClassName(REACT_ON_RAILS_COMPONENT_CLASS_NAME);
  for (let i = 0; i < els.length; i++) {
    fn(els[i]);
  }
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

  if (!turbolinksInstalled && expectTurboLinks) {
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
        throw new Error('You returned a server side type of react-router error: ' +
          JSON.stringify(reactElementOrRouterResult) +
          '\nYou should return a React.Component always for the client side entry point.');
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
  forEachComponent(render);
}

function unmount(el) {
  const domNodeId = el.getAttribute('data-dom-id');
  const domNode = document.getElementById(domNodeId);
  ReactDOM.unmountComponentAtNode(domNode);
}

function reactOnRailsPageUnloaded() {
  forEachComponent(unmount);
}

let ranOnce = false;

export default function clientStartup(context) {
  if (ranOnce) {
    return;
  }

  const document = context.document;

  // Install listeners when running on the client (browser)
  if (typeof document !== 'undefined') {
    if (!turbolinksInstalled) {
      document.addEventListener('DOMContentLoaded', reactOnRailsPageLoaded);
    } else {
      document.addEventListener('page:before-unload', reactOnRailsPageUnloaded);
      document.addEventListener('page:change', reactOnRailsPageLoaded);
    }
  }

  ranOnce = true;
}
