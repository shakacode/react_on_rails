import type { ReactElement } from 'react';
import type { RegisteredComponent, RailsContext, RenderReturnType } from './types/index.ts';
import ComponentRegistry from './ComponentRegistry.ts';
import StoreRegistry from './StoreRegistry.ts';
import createReactOutput from './createReactOutput.ts';
import reactHydrateOrRender from './reactHydrateOrRender.ts';
import { getRailsContext } from './context.ts';
import { isServerRenderHash } from './isServerRenderResult.ts';
import { onPageUnloaded } from './pageLifecycle.ts';
import { supportsRootApi, unmountComponentAtNode } from './reactApis.cts';

const REACT_ON_RAILS_STORE_ATTRIBUTE = 'data-js-react-on-rails-store';

// Track all rendered roots for cleanup
const renderedRoots = new Map<string, { root: RenderReturnType; domNode: Element }>();

function initializeStore(el: Element, railsContext: RailsContext): void {
  const name = el.getAttribute(REACT_ON_RAILS_STORE_ATTRIBUTE) || '';
  const props = el.textContent !== null ? (JSON.parse(el.textContent) as Record<string, unknown>) : {};
  const storeGenerator = StoreRegistry.getStoreGenerator(name);
  const store = storeGenerator(props, railsContext);
  StoreRegistry.setStore(name, store);
}

function forEachStore(railsContext: RailsContext): void {
  const els = document.querySelectorAll(`[${REACT_ON_RAILS_STORE_ATTRIBUTE}]`);
  for (let i = 0; i < els.length; i += 1) {
    initializeStore(els[i], railsContext);
  }
}

function domNodeIdForEl(el: Element): string {
  return el.getAttribute('data-dom-id') || '';
}

function delegateToRenderer(
  componentObj: RegisteredComponent,
  props: Record<string, unknown>,
  railsContext: RailsContext,
  domNodeId: string,
  trace: boolean,
): boolean {
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
    (component as (props: Record<string, unknown>, railsContext: RailsContext, domNodeId: string) => void)(
      props,
      railsContext,
      domNodeId,
    );
    return true;
  }

  return false;
}

/**
 * Used for client rendering by ReactOnRails. Either calls ReactDOM.hydrate, ReactDOM.render, or
 * delegates to a renderer registered by the user.
 */
function renderElement(el: Element, railsContext: RailsContext): void {
  // This must match lib/react_on_rails/helper.rb
  const name = el.getAttribute('data-component-name') || '';
  const domNodeId = domNodeIdForEl(el);
  const props = el.textContent !== null ? (JSON.parse(el.textContent) as Record<string, unknown>) : {};
  const trace = el.getAttribute('data-trace') === 'true';

  try {
    const domNode = document.getElementById(domNodeId);
    if (domNode) {
      // Skip if this component was already rendered by a previous call
      // This prevents hydration errors when reactOnRailsPageLoaded() is called multiple times
      // (e.g., for asynchronously loaded content)
      if (renderedRoots.has(domNodeId)) {
        if (trace) {
          console.log(`Skipping already rendered component: ${name} (dom id: ${domNodeId})`);
        }
        return;
      }

      const componentObj = ComponentRegistry.get(name);
      if (delegateToRenderer(componentObj, props, railsContext, domNodeId, trace)) {
        return;
      }

      // Hydrate if the DOM node has content (server-rendered HTML)
      // Since we skip already-rendered components above, this check now correctly
      // identifies only server-rendered content, not previously client-rendered content
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
        const root = reactHydrateOrRender(domNode, reactElementOrRouterResult as ReactElement, shouldHydrate);
        // Track the root for cleanup
        renderedRoots.set(domNodeId, { root, domNode });
      }
    }
  } catch (e: unknown) {
    const error = e as Error;
    console.error(error.message);
    error.message = `ReactOnRails encountered an error while rendering component: ${name}. See above error message.`;
    throw error;
  }
}

/**
 * Render a single component by its DOM ID.
 * This is the main entry point for rendering individual components.
 * @public
 */
export function renderComponent(domId: string): void {
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
 * Render all components on the page.
 * Core package renders all components after page load.
 */
export function renderAllComponents(): void {
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
export function reactOnRailsComponentLoaded(domId: string): Promise<void> {
  renderComponent(domId);
  return Promise.resolve();
}

/**
 * Unmount all rendered React components and clear roots.
 * This should be called on page unload to prevent memory leaks.
 */
function unmountAllComponents(): void {
  renderedRoots.forEach(({ root, domNode }) => {
    try {
      if (supportsRootApi && root && typeof root === 'object' && 'unmount' in root) {
        // React 18+ Root API
        root.unmount();
      } else {
        // React 16-17 legacy API
        unmountComponentAtNode(domNode);
      }
    } catch (error) {
      console.error('Error unmounting component:', error);
    }
  });
  renderedRoots.clear();
}

// Register cleanup on page unload
onPageUnloaded(unmountAllComponents);
