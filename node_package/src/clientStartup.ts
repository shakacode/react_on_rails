import ReactDOM from 'react-dom';
import type { ReactElement } from 'react';
import type {
  RailsContext,
  ReactOnRails as ReactOnRailsType,
  RegisteredComponent,
  RenderFunction,
} from './types/index';

import createReactOutput from './createReactOutput';
import isServerRenderResult from './isServerRenderResult';

declare global {
  interface Window {
      ReactOnRails: ReactOnRailsType;
      __REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__?: boolean;
  }
  namespace NodeJS {
    interface Global {
        ReactOnRails: ReactOnRailsType;
    }
  }
  namespace Turbolinks {
    interface TurbolinksStatic {
      controller?: {};
    }
  }
}

declare const ReactOnRails: ReactOnRailsType;

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
  if (context.ReactOnRails && context.ReactOnRails.option('traceTurbolinks')) {
    console.log('TURBO:', ...msg);
  }
}

function turbolinksInstalled(): boolean {
  return (typeof Turbolinks !== 'undefined');
}

function reactOnRailsHtmlElements() {
  return document.getElementsByClassName('js-react-on-rails-component');
}

function forEachReactOnRailsComponentInitialize(fn: (element: Element, railsContext: RailsContext) => void, railsContext: RailsContext): void {
  const els = reactOnRailsHtmlElements();
  for (let i = 0; i < els.length; i += 1) {
    fn(els[i], railsContext);
  }
}

function initializeStore(el: Element, railsContext: RailsContext): void {
  const context = findContext();
  const name = el.getAttribute(REACT_ON_RAILS_STORE_ATTRIBUTE) || "";
  const props = (el.textContent !== null) ? JSON.parse(el.textContent) : {};
  const storeGenerator = context.ReactOnRails.getStoreGenerator(name);
  const store = storeGenerator(props, railsContext);
  context.ReactOnRails.setStore(name, store);
}

function forEachStore(railsContext: RailsContext): void {
  const els = document.querySelectorAll(`[${REACT_ON_RAILS_STORE_ATTRIBUTE}]`);
  for (let i = 0; i < els.length; i += 1) {
    initializeStore(els[i], railsContext);
  }
}

function turbolinksVersion5(): boolean {
  return (typeof Turbolinks.controller !== 'undefined');
}

function turbolinksSupported(): boolean {
  return Turbolinks.supported;
}

function delegateToRenderer(
  componentObj: RegisteredComponent,
  props: Record<string, string>,
  railsContext: RailsContext,
  domNodeId: string,
  trace: boolean
): boolean {
  const { name, component, isRenderer } = componentObj;

  if (isRenderer) {
    if (trace) {
      console.log(`\
DELEGATING TO RENDERER ${name} for dom node with id: ${domNodeId} with props, railsContext:`,
      props, railsContext);
    }

    (component as RenderFunction)(props, railsContext, domNodeId);
    return true;
  }

  return false;
}

function domNodeIdForEl(el: Element): string {
  return el.getAttribute('data-dom-id') || "";
}

/**
 * Used for client rendering by ReactOnRails. Either calls ReactDOM.hydrate, ReactDOM.render, or
 * delegates to a renderer registered by the user.
 * @param el
 */
function render(el: Element, railsContext: RailsContext): void {
  const context = findContext();
  // This must match lib/react_on_rails/helper.rb
  const name = el.getAttribute('data-component-name') || "";
  const domNodeId = domNodeIdForEl(el);
  const props = (el.textContent !== null) ? JSON.parse(el.textContent) : {};
  const trace = el.getAttribute('data-trace') === "true";

  try {
    const domNode = document.getElementById(domNodeId);
    if (domNode) {
      const componentObj = context.ReactOnRails.getComponent(name);
      if (delegateToRenderer(componentObj, props, railsContext, domNodeId, trace)) {
        return;
      }

      // Hydrate if available and was server rendered
      const shouldHydrate = !!ReactDOM.hydrate && !!domNode.innerHTML;

      const reactElementOrRouterResult = createReactOutput({
        componentObj,
        props,
        domNodeId,
        trace,
        railsContext,
        shouldHydrate,
      });

      if (isServerRenderResult(reactElementOrRouterResult)) {
        throw new Error(`\
You returned a server side type of react-router error: ${JSON.stringify(reactElementOrRouterResult)}
You should return a React.Component always for the client side entry point.`);
      } else if (shouldHydrate) {
        ReactDOM.hydrate(reactElementOrRouterResult as ReactElement, domNode);
      } else {
        ReactDOM.render(reactElementOrRouterResult as ReactElement, domNode);
      }
    }
  } catch (e) {
    e.message = `ReactOnRails encountered an error while rendering component: ${name}.\n` +
      `Original message: ${e.message}`;
    throw e;
  }
}

function parseRailsContext(): RailsContext | null {
  const el = document.getElementById('js-react-on-rails-context');
  if (!el) {
    // The HTML page will not have an element with ID 'js-react-on-rails-context' if there are no
    // react on rails components
    return null;
  }

  if (!el.textContent) {
    throw new Error("The HTML element with ID 'js-react-on-rails-context' has no textContent");
  }

  return JSON.parse(el.textContent);
}

export function reactOnRailsPageLoaded(): void {
  debugTurbolinks('reactOnRailsPageLoaded');

  const railsContext = parseRailsContext();

  // If no react on rails components
  if (!railsContext) return;

  forEachStore(railsContext);
  forEachReactOnRailsComponentInitialize(render, railsContext);
}

function unmount(el: Element): void {
  const domNodeId = domNodeIdForEl(el);
  const domNode = document.getElementById(domNodeId);
  if(domNode === null){return;}
  try {
    ReactDOM.unmountComponentAtNode(domNode);
  } catch (e) {
    console.info(`Caught error calling unmountComponentAtNode: ${e.message} for domNode`,
      domNode, e);
  }
}

function reactOnRailsPageUnloaded(): void {
  debugTurbolinks('reactOnRailsPageUnloaded');
  const els = reactOnRailsHtmlElements();
  for (let i = 0; i < els.length; i += 1) {
    unmount(els[i]);
  }
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
