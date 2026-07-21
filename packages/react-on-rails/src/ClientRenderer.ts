import type { ReactElement } from 'react';
import type {
  RegisteredComponent,
  RailsContext,
  RendererFunction,
  RendererTeardown,
  RenderReturnType,
  RegisteredComponentValue,
} from './types/index.ts';
import ComponentRegistry from './ComponentRegistry.ts';
import StoreRegistry from './StoreRegistry.ts';
import createReactOutput from './createReactOutput.ts';
import reactHydrateOrRender from './reactHydrateOrRender.ts';
import { getRailsContext } from './context.ts';
import { isServerRenderHash } from './isServerRenderResult.ts';
import { onPageUnloaded } from './pageLifecycle.ts';
import { supportsRootApi, unmountComponentAtNode } from './reactApis.cts';
import { isRendererTeardownResult } from './rendererTeardown.ts';
import { buildRootErrorCallbackOptions } from './rootErrorHandlers.ts';
import { convertToError } from './errorUtils.ts';
import { isThenable } from './isThenable.ts';

const REACT_ON_RAILS_STORE_ATTRIBUTE = 'data-js-react-on-rails-store';

type RendererResult = ReturnType<RendererFunction>;
type RegisteredComponentEntry = RegisteredComponent<RegisteredComponentValue>;
type HydrateOnMode = 'immediate' | 'visible' | 'idle';
type IdleCallbackHandle = number;
type WindowWithIdleCallback = Window & {
  requestIdleCallback?: (callback: () => void, options?: { timeout: number }) => IdleCallbackHandle;
  cancelIdleCallback?: (handle: IdleCallbackHandle) => void;
};
type ScheduledRenderEntry = {
  kind: 'scheduled';
  cancel: () => void;
  // Retained for same-node replacement detection: renderElement reads `entry.domNode` when an
  // existing scheduled entry occupies the same `domNodeId` to decide whether to skip or evict it.
  domNode: Element;
};

// An entry in `renderedRoots`. We track two kinds of mounts so both can be cleaned up on page
// unload or same-id node replacement:
// - `react`: a React root (or legacy backing instance) that ReactOnRails created itself.
// - `renderer`: a user renderer function (3-arg form) that owns its own mount; cleanup runs the
//   optional teardown it returned. The `domNode` reference is retained so same-id node replacement can
//   be detected before running the old teardown. `teardown` is undefined only while an async teardown
//   has not resolved yet — `trackRendererMount` only attaches a late-resolving teardown while this
//   entry is still the active mount for its id.
// - `scheduled`: a framework-owned React root that has not mounted yet because `hydrate_on` deferred
//   it. Cleanup cancels the pending observer or idle callback before Turbo/Turbolinks swaps the page.
type RenderedEntry =
  | { kind: 'react'; root: RenderReturnType; domNode: Element }
  | { kind: 'renderer'; teardown?: RendererTeardown; domNode: Element }
  | ScheduledRenderEntry;

// Track all rendered roots for cleanup
const renderedRoots = new Map<string, RenderedEntry>();

/**
 * Invokes a renderer teardown, swallowing async rejections so a failing teardown cannot produce an
 * unhandled promise rejection. Synchronous throws propagate to the caller's try/catch. `domNodeId`
 * is included in the log so a failure can be traced to its mount.
 * MIRROR OF: packages/react-on-rails-pro/src/ClientSideRenderer.ts (sibling helper). If you change
 * the error-handling logic or log format here, update that copy too.
 */
function invokeRendererTeardown(teardown: RendererTeardown | undefined, domNodeId: string): void {
  if (!teardown) return;
  const maybePromise = teardown();
  if (isThenable(maybePromise)) {
    // Detect a thenable with `.then` (Promises/A+) but swallow the rejection via
    // `Promise.resolve(...).catch(...)`: a non-native thenable may lack `.catch`, so calling it
    // directly could itself throw or leave the rejection unhandled. This keeps a failing async
    // teardown from surfacing as an unhandled promise rejection.
    Promise.resolve(maybePromise).catch((error: unknown) => {
      console.error(`Error in renderer teardown for dom node "${domNodeId}":`, error);
    });
  }
}

/**
 * Tears down a single tracked entry: runs the renderer's teardown, or unmounts the React root.
 * Synchronous errors are not caught here; callers wrap this in try/catch so one failure does not
 * abort cleanup of the remaining entries.
 */
function teardownEntry(entry: RenderedEntry, domNodeId: string): void {
  if (entry.kind === 'scheduled') {
    entry.cancel();
    return;
  }
  if (entry.kind === 'renderer') {
    invokeRendererTeardown(entry.teardown, domNodeId);
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

function teardownErrorLabel(entry: RenderedEntry, domNodeId: string): string {
  if (entry.kind === 'renderer') {
    return `Error in renderer teardown for dom node "${domNodeId}":`;
  }

  if (entry.kind === 'scheduled') {
    return `Error canceling scheduled render for dom node "${domNodeId}":`;
  }

  return `Error unmounting component for dom node "${domNodeId}":`;
}

function initializeStore(el: Element, railsContext: RailsContext): void {
  const name = el.getAttribute(REACT_ON_RAILS_STORE_ATTRIBUTE) || '';

  // Guard: don't re-create an already-hydrated store.
  // Before hydrate_on scheduling (#4037), all components hydrated in one synchronous pass, so every
  // component read the same store instance created in that pass. Deferred hydration (visible/idle)
  // breaks that invariant: forEachStore can run again (e.g. via reactOnRailsComponentLoaded for a
  // Turbo Frame), re-creating the store while an already-hydrated :immediate sibling keeps the old
  // instance and a not-yet-mounted :visible sibling will get the new one — divergent shared state.
  // Skipping re-initialization restores the one-instance-per-name-per-page-lifetime invariant.
  // See: https://github.com/shakacode/react_on_rails/issues/4572
  if (StoreRegistry.getStore(name, false) !== undefined) {
    return;
  }

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

function hydrateOnForEl(el: Element): HydrateOnMode {
  const hydrateOn = el.getAttribute('data-hydrate-on');
  if (!hydrateOn || hydrateOn === 'immediate' || hydrateOn === 'visible' || hydrateOn === 'idle') {
    return (hydrateOn || 'immediate') as HydrateOnMode;
  }

  console.warn(`[react-on-rails] Unsupported hydrate_on: ${hydrateOn}.`);
  return 'immediate';
}

function hasObservableArea(element: Element): boolean {
  const rects = element.getClientRects();
  for (let index = 0; index < rects.length; index += 1) {
    const rect = rects[index];
    if (rect.width > 0 && rect.height > 0) return true;
  }

  const boundingRect = element.getBoundingClientRect();
  return boundingRect.width > 0 && boundingRect.height > 0;
}

function scheduleTimeout(callback: () => void, delay: number): () => void {
  const timeoutId = window.setTimeout(callback, delay);
  return () => window.clearTimeout(timeoutId);
}

function scheduleWhenVisible(domNode: Element, callback: () => void): () => void {
  if (typeof IntersectionObserver === 'undefined') {
    console.warn('[react-on-rails] No IntersectionObserver.');
    return scheduleTimeout(callback, 0);
  }

  if (!domNode.hasChildNodes() && !hasObservableArea(domNode)) {
    return scheduleTimeout(callback, 0);
  }

  const observer = new IntersectionObserver(
    (entries) => {
      // Disconnect early if the target was removed outside Turbo navigation to avoid a
      // leaked observer holding a live reference to a detached node.
      const target = entries[0]?.target;
      if (target && !target.isConnected) {
        observer.disconnect();
        callback();
        return;
      }
      const isVisible = entries.some((entry) => entry.isIntersecting || entry.intersectionRatio > 0);
      if (!isVisible) return;

      observer.disconnect();
      callback();
    },
    { rootMargin: '200px 0px' },
  );
  observer.observe(domNode);

  return () => {
    observer.disconnect();
  };
}

function scheduleWhenIdle(callback: () => void): () => void {
  const idleWindow = window as WindowWithIdleCallback;
  if (typeof idleWindow.requestIdleCallback === 'function') {
    const idleCallbackId = idleWindow.requestIdleCallback(callback, { timeout: 2000 });
    return () => {
      if (typeof idleWindow.cancelIdleCallback === 'function') {
        idleWindow.cancelIdleCallback(idleCallbackId);
      }
    };
  }

  // Safari lacks requestIdleCallback; 50 ms defers past the current frame without a layout-blocking
  // setTimeout(0) but still far enough before most long-idle periods (matching common polyfill defaults).
  return scheduleTimeout(callback, 50);
}

function scheduleHydration(hydrateOn: HydrateOnMode, domNode: Element, callback: () => void): () => void {
  if (hydrateOn === 'visible') {
    return scheduleWhenVisible(domNode, callback);
  }

  if (hydrateOn === 'idle') {
    return scheduleWhenIdle(callback);
  }

  // Defensive: `renderElement` short-circuits for `immediate` before calling `scheduleHydration`, so
  // this branch is normally unreachable; it acts as a safe fallback guard for future callers.
  callback();
  return () => {};
}

type ErrorWithCause = Error & { cause?: unknown };

// Logs a normalized copy of the original thrown value, then returns a fresh ReactOnRails-prefixed
// error for callers to throw/report. This must not mutate the original value: user code can throw
// strings, null, cross-realm errors, or frozen Error instances, and delayed hydration catches run
// inside scheduler callbacks where an error reporter that throws would escape the callback.
function prepareRenderError(componentName: string, error: unknown): Error {
  const originalError = convertToError(error);
  console.error(originalError);

  const renderError = new Error(
    `ReactOnRails encountered an error while rendering component: ${componentName}. See above error message.`,
  ) as ErrorWithCause;
  renderError.cause = originalError;
  if (typeof originalError.stack === 'string') {
    renderError.stack = originalError.stack;
  }
  return renderError;
}

function raiseRenderError(componentName: string, error: unknown): never {
  throw prepareRenderError(componentName, error);
}

function reportRenderError(componentName: string, error: unknown): void {
  // prepareRenderError already logged the original error; do not log again (avoids the double-log).
  prepareRenderError(componentName, error);
}

// Result of attempting renderer delegation. Core carries the raw RendererResult (which may still be
// a pending promise) because renderElement is synchronous and defers async-teardown handling to
// trackRendererMount. The Pro renderer has its own DelegationResult that instead pre-resolves to a
// teardown (it can await the renderer); the two intentionally differ and are not meant to be unified.
type DelegationResult = { delegated: false } | { delegated: true; result: RendererResult };

function delegateToRenderer(
  componentObj: RegisteredComponentEntry,
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

    // Call the renderer function with the expected signature. A renderer owns its own mount and may
    // return nothing, a teardown wrapper, or a promise resolving to one. `component` is the registered
    // component union, so `as RendererFunction` is a runtime-invariant assertion guarded by
    // `isRenderer` (the registry only sets it for a 3-arg render function), not a structural
    // narrowing.
    if (typeof component !== 'function') {
      throw new Error(`Registered renderer "${name}" must be a function.`);
    }

    const result = (component as RendererFunction)(props, railsContext, domNodeId);
    return { delegated: true, result };
  }

  return { delegated: false };
}

/**
 * Records a renderer-function mount and captures its optional teardown. The renderer may return a
 * teardown wrapper synchronously, or a promise resolving to one (async renderers). The entry is
 * stored immediately so the replaced-node path can find it even before an async teardown resolves.
 *
 * Known limitation (core package): if the mount is unmounted or its node is replaced *before* an
 * async renderer resolves its teardown, the still-pending teardown is dropped and that one mount
 * leaks — the resolved teardown is discarded because the entry is no longer the active mount for
 * this id (the `renderedRoots.get(domNodeId) === entry` guard below). The drop is an expected,
 * documented core limitation, but it still leaves a renderer-owned mount uncleaned, so it is logged
 * with `console.error` rather than silently ignored. Synchronous teardowns are unaffected. The Pro
 * client renderer (`react-on-rails-pro`) awaits the renderer and re-checks the unmount state, so it
 * runs the teardown even when a navigation races the resolve; prefer Pro if you depend on async
 * renderer teardowns surviving fast navigations.
 *
 * Renderer results that ultimately do not include a teardown wrapper are left untracked:
 * synchronous no-wrapper returns are not stored, and async results that resolve without a wrapper use
 * only a temporary placeholder until the promise settles. Before this cleanup contract existed,
 * renderer-owned mounts were never tracked, so repeated page-loaded calls re-invoked those legacy
 * renderers; preserving that behavior keeps "return nothing" backward compatible.
 */
function trackRendererMount(domNodeId: string, domNode: Element, result: RendererResult): void {
  if (isRendererTeardownResult(result)) {
    renderedRoots.set(domNodeId, { kind: 'renderer', domNode, teardown: result.teardown });
  } else if (isThenable(result)) {
    const entry: RenderedEntry = { kind: 'renderer', domNode, teardown: undefined };
    renderedRoots.set(domNodeId, entry);
    Promise.resolve(result)
      .then((resolved) => {
        if (!isRendererTeardownResult(resolved)) {
          if (renderedRoots.get(domNodeId) === entry) {
            renderedRoots.delete(domNodeId);
          }
          return;
        }
        // Only attach if this exact entry is still the active mount for this id.
        if (renderedRoots.get(domNodeId) === entry) {
          entry.teardown = resolved.teardown;
        } else {
          // The mount was unmounted or its node replaced before this async teardown resolved, so the
          // entry is no longer the active mount and the teardown can't be attached — it is dropped
          // and that one mount may leak on cleanup. This is the expected, documented best-effort core
          // limitation, but the consequence is still a leak, so log it as an error. Pro avoids this
          // race entirely.
          console.error(
            `[react-on-rails] Renderer teardown for dom node "${domNodeId}" resolved after the ` +
              'page or node was already cleaned up; the teardown was dropped and that mount may ' +
              'leak. Use react-on-rails-pro for reliable async-renderer teardown on fast navigations.',
          );
        }
      })
      .catch((error: unknown) => {
        const isStillActive = renderedRoots.get(domNodeId) === entry;
        if (!isStillActive) {
          return;
        }
        renderedRoots.delete(domNodeId);
        // The renderer's own promise rejected: the render failed, so the component never mounted and
        // no teardown was captured. Log it (rather than letting it surface as an unhandled rejection)
        // so the failure is diagnosable; any partial mount the renderer created may leak on cleanup.
        // If this placeholder was already removed by page unload or node replacement, the page/node is
        // already being cleaned up, so suppress a stale rejection log from the abandoned renderer.
        console.error(
          `Renderer for dom node "${domNodeId}" rejected; the component did not mount and no ` +
            'teardown was captured. Any mount it created may leak on cleanup:',
          error,
        );
      });
  }
}

/**
 * Used for client rendering by ReactOnRails. Either calls ReactDOM.hydrate, ReactDOM.render, or
 * delegates to a renderer registered by the user.
 */
function renderElement(el: Element, railsContext: RailsContext): void {
  // This must match the data-* attributes emitted by lib/react_on_rails/pro_helper.rb.
  // Covered end-to-end by every spec/dummy client-rendering test (renaming either side fails
  // loudly), so no MIRROR VALUES guard is added here.
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
        // Only skip if it's the exact same DOM node, it's still connected to the document, AND it has
        // actually mounted. A `scheduled` entry has not mounted yet: if its node was detached and later
        // reattached (e.g. Turbo cache restore or a DOM move), its IntersectionObserver was disconnected
        // and will never re-observe, so we must fall through to cancel the stale schedule and re-schedule
        // fresh rather than skip (which would leave the island permanently non-interactive).
        // If the node was replaced (e.g., via innerHTML or Turbo), we likewise need to unmount/cancel the
        // old entry and re-render to the new node to prevent memory leaks and ensure rendering works.
        const sameNode =
          existing.kind !== 'scheduled' && existing.domNode === domNode && existing.domNode.isConnected;
        if (sameNode) {
          if (trace) {
            console.log(`Skipping already rendered component: ${name} (dom id: ${domNodeId})`);
          }
          return;
        }
        // DOM node was replaced (e.g., via async HTML injection) - clean up the old root or run
        // the old renderer's teardown.
        try {
          teardownEntry(existing, domNodeId);
        } catch (unmountError) {
          // Surface the failure unconditionally (matching unmountAllComponents) so a teardown/unmount
          // error on node replacement is as visible as one on page unload, using the same greppable
          // labels. We still continue: the old mount may leak, but the new node must be rendered.
          console.error(teardownErrorLabel(existing, domNodeId), unmountError);
        }
        renderedRoots.delete(domNodeId);
      }

      const componentObj = ComponentRegistry.get(name);
      const delegation = delegateToRenderer(componentObj, props, railsContext, domNodeId, trace);
      if (delegation.delegated) {
        // The renderer owns its own mount; record it (with any teardown wrapper it returned) so it
        // gets cleaned up on page unload or same-id node replacement.
        trackRendererMount(domNodeId, domNode, delegation.result);
        return;
      }

      const mountReactRoot = (): void => {
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
        }

        const root = reactHydrateOrRender(
          domNode,
          reactElementOrRouterResult as ReactElement,
          shouldHydrate,
          // Attach user-registered root error callbacks (and the dev-mode hydration-mismatch
          // logger) to every root, enriched with this mount's component name and dom id.
          buildRootErrorCallbackOptions(
            { componentName: name || undefined, domNodeId: domNodeId || undefined },
            shouldHydrate,
          ),
        );
        // Track the root for cleanup
        renderedRoots.set(domNodeId, { kind: 'react', root, domNode });
      };

      const hydrateOn = hydrateOnForEl(el);
      if (hydrateOn === 'immediate') {
        mountReactRoot();
        return;
      }

      let scheduledEntry: ScheduledRenderEntry;
      const runScheduledRender = (): void => {
        if (renderedRoots.get(domNodeId) !== scheduledEntry) return;
        if (!domNode.isConnected) {
          renderedRoots.delete(domNodeId);
          return;
        }

        try {
          mountReactRoot();
        } catch (scheduledError) {
          renderedRoots.delete(domNodeId);
          reportRenderError(name, scheduledError);
        }
      };

      scheduledEntry = {
        kind: 'scheduled',
        domNode,
        cancel: scheduleHydration(hydrateOn, domNode, runScheduledRender),
      };
      renderedRoots.set(domNodeId, scheduledEntry);
    }
  } catch (e: unknown) {
    raiseRenderError(name, e);
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
 * Registered with `onPageUnloaded` to run on the page-unload lifecycle (Turbo/Turbolinks
 * soft-navigation page swap, not a native browser unload) to prevent memory leaks.
 */
function unmountAllComponents(): void {
  renderedRoots.forEach((entry, domNodeId) => {
    try {
      teardownEntry(entry, domNodeId);
    } catch (error) {
      console.error(teardownErrorLabel(entry, domNodeId), error);
    }
  });
  renderedRoots.clear();
}

/**
 * Clear all hydrated stores on page unload so navigation to a new page re-initializes stores
 * with the new page's props. Without this, the initializeStore guard (which prevents duplicate
 * store creation within a single page lifecycle) would skip re-initialization on navigation,
 * leaving components bound to stale state from the previous page.
 */
function clearAllStores(): void {
  StoreRegistry.clearHydratedStores();
}

// Register cleanup on page unload
onPageUnloaded(unmountAllComponents);
onPageUnloaded(clearAllStores);
