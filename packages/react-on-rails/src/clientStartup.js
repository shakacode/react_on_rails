// Core package: Renders all components after full page load
// Pro package: Can hydrate before page load (immediate_hydration) and supports on-demand rendering
import { renderAllComponents } from './ClientRenderer.js';
import { onPageLoaded } from './pageLifecycle.js';
import { debugTurbolinks } from './turbolinksUtils.js';
export async function reactOnRailsPageLoaded() {
  debugTurbolinks('reactOnRailsPageLoaded');
  // Core package: Render all components after page is fully loaded
  renderAllComponents();
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
  // Pro package: Can start hydration immediately (immediate_hydration: true) or wait for page load
  onPageLoaded(reactOnRailsPageLoaded);
}
//# sourceMappingURL=clientStartup.js.map
