// Core package: Renders all components after full page load
// Pro package: Can hydrate before page load and supports on-demand rendering
import { renderAllComponents, renderComponentsWithin, unmountDetachedComponents } from './ClientRenderer.ts';
import { onPageLoaded } from './pageLifecycle.ts';
import { debugTurbolinks, turboInstalled } from './turbolinksUtils.ts';

export function reactOnRailsPageLoaded() {
  debugTurbolinks('reactOnRailsPageLoaded');
  // Core package: Render all components after page is fully loaded
  renderAllComponents();
}

// A Turbo Frame navigation replaces only the frame's content and fires turbo:frame-render instead
// of turbo:before-render/turbo:render, so the page lifecycle never sees it. Once the frame has
// rendered, unmount the components whose nodes the render removed and mount the ones in the new
// content. Cleaning up after the render, not on turbo:before-frame-render, leaves components intact
// when an app pauses or cancels the render (e.g. to animate the frame). The Pro package has its own
// startup (proClientStartup) and does not install this listener; it mounts frame content through
// the inline script each component emits.
function onTurboFrameRender(event: Event): void {
  if (!turboInstalled() || !(event.target instanceof Element)) return;
  debugTurbolinks(`turbo:frame-render: frame #${event.target.id}`);
  unmountDetachedComponents();
  renderComponentsWithin(event.target);
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
  document.addEventListener('turbo:frame-render', onTurboFrameRender);
}
