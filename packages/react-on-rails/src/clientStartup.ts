// Core package: Renders all components after full page load
// Pro package: Can hydrate before page load and supports on-demand rendering
import {
  mountedComponentIdsWithin,
  renderAllComponents,
  renderComponentsWithin,
  unmountDetachedComponents,
} from './ClientRenderer.ts';
import { onPageLoaded } from './pageLifecycle.ts';
import { debugTurbolinks, turboInstalled } from './turbolinksUtils.ts';

export function reactOnRailsPageLoaded() {
  debugTurbolinks('reactOnRailsPageLoaded');
  // Core package: Render all components after page is fully loaded
  renderAllComponents();
}

// A Turbo Frame navigation replaces only the frame's content and fires frame events instead of
// turbo:before-render/turbo:render, so the page lifecycle never sees it. Before the render, record
// which components the frame holds; after it, unmount those the render removed and mount the new
// content. Unmounting only after turbo:frame-render leaves components intact when an app pauses or
// cancels the render (e.g. to animate the frame), and limiting it to the recorded ids leaves alone
// components elsewhere that happen to be detached at that moment. The Pro package has its own
// startup (proClientStartup) with its own frame listeners; it mounts frame content through the
// inline script each component emits.
const componentIdsBeforeFrameRender = new WeakMap<Element, string[]>();

function turboFrameTarget(event: Event): Element | null {
  if (!turboInstalled() || !(event.target instanceof Element)) return null;
  debugTurbolinks(`${event.type}: frame #${event.target.id}`);
  return event.target;
}

function onTurboBeforeFrameRender(event: Event): void {
  const frame = turboFrameTarget(event);
  if (frame) componentIdsBeforeFrameRender.set(frame, mountedComponentIdsWithin(frame));
}

function onTurboFrameRender(event: Event): void {
  const frame = turboFrameTarget(event);
  if (!frame) return;
  unmountDetachedComponents(componentIdsBeforeFrameRender.get(frame) ?? []);
  componentIdsBeforeFrameRender.delete(frame);
  renderComponentsWithin(frame);
}

export function clientStartup() {
  // Check if server rendering
  if (globalThis.document === undefined) {
    return;
  }

  // Tried with a file local variable, but the install handler gets called twice.
  // eslint-disable-next-line no-underscore-dangle
  if (globalThis.__REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__) {
    return;
  }

  // eslint-disable-next-line no-underscore-dangle
  globalThis.__REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__ = true;

  // Core package: Wait for full page load, then render all components
  // Pro package: Can start hydration immediately or wait for page load
  onPageLoaded(reactOnRailsPageLoaded);
  document.addEventListener('turbo:before-frame-render', onTurboBeforeFrameRender);
  document.addEventListener('turbo:frame-render', onTurboFrameRender);
}
