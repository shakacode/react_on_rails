import ComponentRegistry from './ComponentRegistry.js';
import StoreRegistry from './StoreRegistry.js';
import createReactOutput from './createReactOutput.js';
import reactHydrateOrRender from './reactHydrateOrRender.js';
import { getRailsContext } from './context.js';
import { isServerRenderHash } from './isServerRenderResult.js';
const REACT_ON_RAILS_STORE_ATTRIBUTE = 'data-js-react-on-rails-store';
function initializeStore(el, railsContext) {
  const name = el.getAttribute(REACT_ON_RAILS_STORE_ATTRIBUTE) || '';
  const props = el.textContent !== null ? JSON.parse(el.textContent) : {};
  const storeGenerator = StoreRegistry.getStoreGenerator(name);
  const store = storeGenerator(props, railsContext);
  StoreRegistry.setStore(name, store);
}
function forEachStore(railsContext) {
  const els = document.querySelectorAll(`[${REACT_ON_RAILS_STORE_ATTRIBUTE}]`);
  for (let i = 0; i < els.length; i += 1) {
    initializeStore(els[i], railsContext);
  }
}
function domNodeIdForEl(el) {
  return el.getAttribute('data-dom-id') || '';
}
function delegateToRenderer(componentObj, props, railsContext, domNodeId, trace) {
  const { name, component, isRenderer } = componentObj;
  if (isRenderer) {
    if (trace) {
      console.log(
        `\
DELEGATING TO RENDERER ${name} for dom node with id: ${domNodeId} with props, railsContext:`,
        props,
        railsContext,
      );
    }
    // Call the renderer function with the expected signature
    component(props, railsContext, domNodeId);
    return true;
  }
  return false;
}
/**
 * Used for client rendering by ReactOnRails. Either calls ReactDOM.hydrate, ReactDOM.render, or
 * delegates to a renderer registered by the user.
 */
function renderElement(el, railsContext) {
  // This must match lib/react_on_rails/helper.rb
  const name = el.getAttribute('data-component-name') || '';
  const domNodeId = domNodeIdForEl(el);
  const props = el.textContent !== null ? JSON.parse(el.textContent) : {};
  const trace = el.getAttribute('data-trace') === 'true';
  try {
    const domNode = document.getElementById(domNodeId);
    if (domNode) {
      const componentObj = ComponentRegistry.get(name);
      if (delegateToRenderer(componentObj, props, railsContext, domNodeId, trace)) {
        return;
      }
      // Hydrate if available and was server rendered
      const shouldHydrate = !!domNode.innerHTML;
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
        reactHydrateOrRender(domNode, reactElementOrRouterResult, shouldHydrate);
      }
    }
  } catch (e) {
    const error = e;
    console.error(error.message);
    error.message = `ReactOnRails encountered an error while rendering component: ${name}. See above error message.`;
    throw error;
  }
}
/**
 * Render a single component by its DOM ID.
 * This is the main entry point for rendering individual components.
 */
export function renderComponent(domId) {
  const railsContext = getRailsContext();
  // If no react on rails context
  if (!railsContext) return;
  // Initialize stores first
  forEachStore(railsContext);
  // Find the element with the matching data-dom-id
  const el = document.querySelector(`[data-dom-id="${domId}"]`);
  if (!el) return;
  renderElement(el, railsContext);
}
/**
 * Render all stores on the page.
 */
export function renderAllStores() {
  const railsContext = getRailsContext();
  if (!railsContext) return;
  forEachStore(railsContext);
}
/**
 * Render all components on the page.
 * Core package renders all components after page load.
 */
export function renderAllComponents() {
  const railsContext = getRailsContext();
  if (!railsContext) return;
  // Initialize all stores first
  forEachStore(railsContext);
  // Render all components
  const componentElements = document.querySelectorAll('.js-react-on-rails-component');
  for (let i = 0; i < componentElements.length; i += 1) {
    renderElement(componentElements[i], railsContext);
  }
}
/**
 * Public API function that can be called to render a component after it has been loaded.
 * This is the function that should be exported and used by the Rails integration.
 * Returns a Promise for API compatibility with pro version.
 */
export function reactOnRailsComponentLoaded(domId) {
  renderComponent(domId);
  return Promise.resolve();
}
//# sourceMappingURL=ClientRenderer.js.map
