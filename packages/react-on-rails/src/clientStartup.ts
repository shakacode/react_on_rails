// Core package: Renders all components after full page load
// Pro package: Can hydrate before page load and supports on-demand rendering
import { renderAllComponents } from './ClientRenderer.ts';
import { consumeInitialPageLoadIfNeeded, onPageLoaded } from './pageLifecycle.ts';
import { debugTurbolinks } from './turbolinksUtils.ts';

function runAutomaticPageLoad(): void {
  debugTurbolinks('reactOnRailsPageLoaded');
  // Core package: Render all components after page is fully loaded
  renderAllComponents();
}

export function clientStartup(): boolean {
  // Check if server rendering
  if (globalThis.document === undefined) {
    return false;
  }

  // Tried with a file local variable, but the install handler gets called twice.
  // eslint-disable-next-line no-underscore-dangle
  if (globalThis.__REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__) {
    return false;
  }

  // eslint-disable-next-line no-underscore-dangle
  globalThis.__REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__ = true;

  // Core package: Wait for full page load, then render all components
  // Pro package: Can start hydration immediately or wait for page load
  onPageLoaded(runAutomaticPageLoad);
  return true;
}

export function reactOnRailsPageLoaded() {
  const startupWasPending = clientStartup();
  if (startupWasPending) {
    consumeInitialPageLoadIfNeeded();
    return;
  }

  if (consumeInitialPageLoadIfNeeded()) {
    return;
  }

  runAutomaticPageLoad();
}
