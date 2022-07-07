import ReactDOM from 'react-dom';
import type { ReactElement } from 'react';
import type {
  RailsContext,
  ReactOnRails as ReactOnRailsType,
  RegisteredComponent,
  RenderFunction,
  Root,
} from './types';

import createReactOutput from './createReactOutput';
import { isServerRenderHash } from './isServerRenderResult';
import reactHydrateOrRender from './reactHydrateOrRender';
import { supportsRootApi } from './reactApis';

declare global {
  interface Window {
    ReactOnRails: ReactOnRailsType;
    __REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__?: boolean;
    roots: Root[];
  }

  namespace NodeJS {
    interface Global {
      ReactOnRails: ReactOnRailsType;
      roots: Root[];
    }
  }
  namespace Turbolinks {
    interface TurbolinksStatic {
      controller?: unknown;
    }
  }
}

declare const ReactOnRails: ReactOnRailsType;

const REACT_ON_RAILS_STORE_ATTRIBUTE = 'data-js-react-on-rails-store';

type Context = Window | NodeJS.Global;

function findContext(): Context {
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

function turboInstalled() {
  const context = findContext();
  if (context.ReactOnRails) {
    return context.ReactOnRails.option('turbo') === true;
  }
  return false;
}

function reactOnRailsHtmlElements(): HTMLCollectionOf<Element> {
  return document.getElementsByClassName('js-react-on-rails-component');
}

function initializeStore(el: Element, context: Context, railsContext: RailsContext): void {
  const name = el.getAttribute(REACT_ON_RAILS_STORE_ATTRIBUTE) || '';
  const props = (el.textContent !== null) ? JSON.parse(el.textContent) : {};
  const storeGenerator = context.ReactOnRails.getStoreGenerator(name);
  const store = storeGenerator(props, railsContext);
  context.ReactOnRails.setStore(name, store);
}

function forEachStore(context: Context, railsContext: RailsContext): void {
  const els = document.querySelectorAll(`[${REACT_ON_RAILS_STORE_ATTRIBUTE}]`);
  for (let i = 0; i < els.length; i += 1) {
    initializeStore(els[i], context, railsContext);
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
  trace: boolean,
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
  return el.getAttribute('data-dom-id') || '';
}

/**
 * Used for client rendering by ReactOnRails. Either calls ReactDOM.hydrate, ReactDOM.render, or
 * delegates to a renderer registered by the user.
 */
function render(el: Element, context: Context, railsContext: RailsContext): void {
  // This must match lib/react_on_rails/helper.rb
  const name = el.getAttribute('data-component-name') || '';
  const domNodeId = domNodeIdForEl(el);
  const props = (el.textContent !== null) ? JSON.parse(el.textContent) : {};
  const trace = el.getAttribute('data-trace') === 'true';

  try {
    const domNode = document.getElementById(domNodeId);
    if (domNode) {
      const componentObj = context.ReactOnRails.getComponent(name);
      if (delegateToRenderer(componentObj, props, railsContext, domNodeId, trace)) {
        return;
      }

      // Hydrate if available and was server rendered
      // @ts-expect-error potentially present if React 18 or greater
      const shouldHydrate = !!(ReactDOM.hydrate || ReactDOM.hydrateRoot) && !!domNode.innerHTML;

      const reactElementOrRouterResult = createReactOutput({
        componentObj,
        props,
        domNodeId,
        trace,
        railsContext,
        shouldHydrate,
      });

      if (isServerRenderHash(reactElementOrRouterResult)) {
        throw new Error(`\
You returned a server side type of react-router error: ${JSON.stringify(reactElementOrRouterResult)}
You should return a React.Component always for the client side entry point.`);
      } else {
        const rootOrElement = reactHydrateOrRender(domNode, reactElementOrRouterResult as ReactElement, shouldHydrate);
        if (supportsRootApi) {
          context.roots.push(rootOrElement as Root);
        }
      }
    }
  } catch (e: any) {
    e.message = `ReactOnRails encountered an error while rendering component: ${name}.\n` +
      `Original message: ${e.message}`;
    throw e;
  }
}

function forEachReactOnRailsComponentRender(context: Context, railsContext: RailsContext): void {
  const els = reactOnRailsHtmlElements();
  for (let i = 0; i < els.length; i += 1) {
    render(els[i], context, railsContext);
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
    throw new Error('The HTML element with ID \'js-react-on-rails-context\' has no textContent');
  }

  return JSON.parse(el.textContent);
}

export function reactOnRailsPageLoaded(): void {
  debugTurbolinks('reactOnRailsPageLoaded');

  const railsContext = parseRailsContext();

  // If no react on rails components
  if (!railsContext) return;

  const context = findContext();
  if (supportsRootApi) {
    context.roots = [];
  }
  forEachStore(context, railsContext);
  forEachReactOnRailsComponentRender(context, railsContext);
}

function unmount(el: Element): void {
  const domNodeId = domNodeIdForEl(el);
  const domNode = document.getElementById(domNodeId);
  if (domNode === null) {
    return;
  }
  try {
    ReactDOM.unmountComponentAtNode(domNode);
  } catch (e: any) {
    console.info(`Caught error calling unmountComponentAtNode: ${e.message} for domNode`,
      domNode, e);
  }
}

function reactOnRailsPageUnloaded(): void {
  debugTurbolinks('reactOnRailsPageUnloaded');
  if (supportsRootApi) {
    for (const root of findContext().roots) {
      root.unmount();
    }
  } else {
    const els = reactOnRailsHtmlElements();
    for (let i = 0; i < els.length; i += 1) {
      unmount(els[i]);
    }
  }
}

function renderInit(): void {
  // Install listeners when running on the client (browser).
  // We must do this check for turbolinks AFTER the document is loaded because we load the
  // Webpack bundles first.
  if ((!turbolinksInstalled() || !turbolinksSupported()) && !turboInstalled()) {
    debugTurbolinks('NOT USING TURBOLINKS: calling reactOnRailsPageLoaded');
    reactOnRailsPageLoaded();
    return;
  }

  if (turboInstalled()) {
    debugTurbolinks(
      'USING TURBO: document added event listeners ' +
      'turbo:before-render and turbo:render.');
    document.addEventListener('turbo:before-render', reactOnRailsPageUnloaded);
    document.addEventListener('turbo:render', reactOnRailsPageLoaded);
    reactOnRailsPageLoaded();
  } else if (turbolinksVersion5()) {
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

function isWindow(context: Context): context is Window {
  return (context as Window).document !== undefined;
}

export function clientStartup(context: Context): void {
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

  // So  long as the document is not loading, we can assume:
  // The document has finished loading and the document has been parsed
  // but sub-resources such as images, stylesheets and frames are still loading.
  // If lazy asynch loading is used, such as with loadable-components, then the init
  // function will install some handler that will properly know when to do hyrdation.
  if (document.readyState !== 'loading') {
    window.setTimeout(renderInit);
  } else {
    document.addEventListener('DOMContentLoaded', renderInit);
  }
}
