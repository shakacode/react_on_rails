import type { ReactElement } from 'react';
import type {
  RegisteredComponent,
  RailsContext,
  RenderFunction,
  RendererTeardown,
  RenderReturnType,
} from './types/index.ts';
import ComponentRegistry from './ComponentRegistry.ts';
import StoreRegistry from './StoreRegistry.ts';
import createReactOutput from './createReactOutput.ts';
import reactHydrateOrRender from './reactHydrateOrRender.ts';
import { getRailsContext } from './context.ts';
import { isServerRenderHash } from './isServerRenderResult.ts';
import { onPageUnloaded } from './pageLifecycle.ts';
import { supportsRootApi, unmountComponentAtNode } from './reactApis.cts';

const REACT_ON_RAILS_STORE_ATTRIBUTE = 'data-js-react-on-rails-store';

// An entry in `renderedRoots`. We track two kinds of mounts so both can be cleaned up on page
// unload or same-id node replacement:
// - `react`: a React root (or legacy backing instance) that ReactOnRails created itself.
// - `renderer`: a user renderer function (3-arg form) that owns its own mount; cleanup runs the
//   optional teardown it returned (undefined when the renderer opted out).
type RenderedEntry =
  | { kind: 'react'; root: RenderReturnType; domNode: Element }
  | { kind: 'renderer'; teardown?: RendererTeardown; domNode: Element };

// Track all rendered roots for cleanup
const renderedRoots = new Map<string, RenderedEntry>();

/**
 * Invokes a renderer teardown, swallowing async rejections so a failing teardown cannot produce an
 * unhandled promise rejection. Synchronous throws propagate to the caller's try/catch.
 */
function invokeRendererTeardown(teardown: RendererTeardown | undefined): void {
  if (!teardown) return;
  const maybePromise = teardown();
  if (maybePromise && typeof maybePromise.catch === 'function') {
    maybePromise.catch((error: unknown) => {
      console.error('Error in renderer teardown:', error);
    });
  }
}

/**
 * Tears down a single tracked entry: runs the renderer's teardown, or unmounts the React root.
 * Synchronous errors are not caught here; callers wrap this in try/catch so one failure does not
 * abort cleanup of the remaining entries.
 */
function teardownEntry(entry: RenderedEntry): void {
  if (entry.kind === 'renderer') {
    invokeRendererTeardown(entry.teardown);
    return;
  }
  if (supportsRootApi && entry.root && typeof entry.root === 'object' && 'unmount' in entry.root) {
    // React 18+ Root API
    entry.root.unmount();
  } else {
    // React 16-17 legacy API
    unmountComponentAtNode(entry.domNode);
  }
}

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

type DelegationResult = { delegated: false } | { delegated: true; result: unknown };

function delegateToRenderer(
  componentObj: RegisteredComponent,
  props: Record<string, unknown>,
  railsContext: RailsContext,
  domNodeId: string,
  trace: boolean,
): DelegationResult {
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

    // Call the renderer function with the expected signature. It may return a teardown callback
    // (or a promise resolving to one) so we can clean up its mount later.
    const result = (component as RenderFunction)(props, railsContext, domNodeId);
    return { delegated: true, result };
  }

  return { delegated: false };
}

/**
 * Records a renderer-function mount and captures its optional teardown. The renderer may return the
 * teardown synchronously, or a promise resolving to one (async renderers). The entry is stored
 * immediately so the replaced-node path can find it even before an async teardown resolves.
 *
 * Known limitation (core package): if the mount is unmounted or its node is replaced *before* an
 * async renderer resolves its teardown, the still-pending teardown is dropped and that one mount
 * leaks — the resolved teardown is discarded because the entry is no longer the active mount for
 * this id (the `renderedRoots.get(domNodeId) === entry` guard below). The drop is logged via
 * `console.error` so it is diagnosable rather than silent. Synchronous teardowns are unaffected.
 * The Pro client renderer (`react-on-rails-pro`) awaits the renderer and re-checks the
 * unmount state, so it runs the teardown even when a navigation races the resolve; prefer Pro if you
 * depend on async renderer teardowns surviving fast navigations.
 */
function trackRendererMount(domNodeId: string, domNode: Element, result: unknown): void {
  const entry: RenderedEntry = { kind: 'renderer', domNode, teardown: undefined };
  renderedRoots.set(domNodeId, entry);

  if (typeof result === 'function') {
    entry.teardown = result as RendererTeardown;
  } else if (result && typeof (result as Promise<unknown>).then === 'function') {
    (result as Promise<unknown>)
      .then((resolved) => {
        if (typeof resolved !== 'function') return;
        // Only attach if this exact entry is still the active mount for this id.
        if (renderedRoots.get(domNodeId) === entry) {
          entry.teardown = resolved as RendererTeardown;
        } else {
          // The mount was unmounted or its node replaced before this async teardown resolved, so the
          // entry is no longer the active mount and the teardown can't be attached — it is dropped
          // and that one mount may leak on cleanup. Log it (rather than dropping silently) so the
          // documented limitation above is diagnosable in production. Pro avoids this race entirely.
          console.error(
            `Renderer teardown for dom node "${domNodeId}" resolved after its mount was removed; ` +
              'the teardown was dropped and that mount may leak on cleanup.',
          );
        }
      })
      .catch((error: unknown) => {
        // The renderer's render promise rejected, so no teardown was captured and this mount will
        // leak on cleanup. Log it (rather than letting it surface as an unhandled rejection) so the
        // dropped teardown is diagnosable, mirroring invokeRendererTeardown above.
        console.error('Error resolving renderer teardown; mount may leak on cleanup:', error);
      });
  }
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
      // Check if this component was already rendered by a previous call
      // This prevents hydration errors when reactOnRailsPageLoaded() is called multiple times
      // (e.g., for asynchronously loaded content)
      const existing = renderedRoots.get(domNodeId);
      if (existing) {
        // Only skip if it's the exact same DOM node and it's still connected to the document.
        // If the node was replaced (e.g., via innerHTML or Turbo), we need to unmount the old
        // root and re-render to the new node to prevent memory leaks and ensure rendering works.
        const sameNode = existing.domNode === domNode && existing.domNode.isConnected;
        if (sameNode) {
          if (trace) {
            console.log(`Skipping already rendered component: ${name} (dom id: ${domNodeId})`);
          }
          return;
        }
        // DOM node was replaced (e.g., via async HTML injection) - clean up the old root or run
        // the old renderer's teardown.
        try {
          teardownEntry(existing);
        } catch (unmountError) {
          // Ignore unmount errors for replaced nodes
          if (trace) {
            console.log(`Error unmounting replaced component: ${name}`, unmountError);
          }
        }
        renderedRoots.delete(domNodeId);
      }

      const componentObj = ComponentRegistry.get(name);
      const delegation = delegateToRenderer(componentObj, props, railsContext, domNodeId, trace);
      if (delegation.delegated) {
        // The renderer owns its own mount; record it (with any teardown it returned) so it gets
        // cleaned up on page unload or same-id node replacement.
        trackRendererMount(domNodeId, domNode, delegation.result);
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
        renderedRoots.set(domNodeId, { kind: 'react', root, domNode });
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
 * Unmount all rendered React components, run all renderer-function teardowns, and clear roots.
 * This should be called on page unload to prevent memory leaks. Exported for testing.
 * @internal
 */
export function unmountAllComponents(): void {
  renderedRoots.forEach((entry) => {
    try {
      teardownEntry(entry);
    } catch (error) {
      // Use the same label as the async-rejection path so renderer-teardown failures are greppable
      // whether the teardown threw synchronously (here) or rejected (invokeRendererTeardown).
      const label = entry.kind === 'renderer' ? 'Error in renderer teardown:' : 'Error unmounting component:';
      console.error(label, error);
    }
  });
  renderedRoots.clear();
}

// Register cleanup on page unload
onPageUnloaded(unmountAllComponents);
