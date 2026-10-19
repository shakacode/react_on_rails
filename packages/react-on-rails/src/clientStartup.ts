// Core package: Renders all components after full page load
// Pro package: Can hydrate before page load and supports on-demand rendering
import { renderAllComponents, renderComponentsWithin, unmountComponentsWithin } from './ClientRenderer.ts';
import { onPageLoaded } from './pageLifecycle.ts';
import { debugTurbolinks, turboInstalled } from './turbolinksUtils.ts';

export function reactOnRailsPageLoaded() {
  debugTurbolinks('reactOnRailsPageLoaded');
  // Core package: Render all components after page is fully loaded
  renderAllComponents();
}

// A Turbo Frame navigation replaces only the frame's content and fires frame events instead of
// turbo:before-render/turbo:render, so the page lifecycle never sees it. Scope cleanup and
// mounting to the frame, leaving components elsewhere on the page alone. The Pro package has its
// own startup and mounts frame content through the inline script each component emits.
function onTurboFrameEvent(event: Event, handler: (frame: Element) => void): void {
  if (!turboInstalled() || !(event.target instanceof Element)) return;
  debugTurbolinks(`${event.type}: frame #${event.target.id}`);
  handler(event.target);
}

function setupTurboFrameListeners(): void {
  document.addEventListener('turbo:before-frame-render', (event) =>
    onTurboFrameEvent(event, unmountComponentsWithin),
  );
  document.addEventListener('turbo:frame-render', (event) =>
    onTurboFrameEvent(event, renderComponentsWithin),
  );
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
  setupTurboFrameListeners();
}
