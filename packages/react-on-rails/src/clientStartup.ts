// Core package provides simple synchronous startup
// Pro package features like immediate hydration and unmounting are not available in core
import { onPageLoaded } from './pageLifecycle.ts';
import { debugTurbolinks } from './turbolinksUtils.ts';

export async function reactOnRailsPageLoaded() {
  debugTurbolinks('reactOnRailsPageLoaded');
  // Core package: Components are rendered on-demand via reactOnRailsComponentLoaded
  // Pro package provides automatic hydration of all components
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

  // Core package: Components are rendered on-demand when Rails calls reactOnRailsComponentLoaded
  // Pro package provides immediate hydration and automatic rendering on page load
  onPageLoaded(reactOnRailsPageLoaded);
}
