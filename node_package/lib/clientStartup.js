import {
  hydrateAllStores,
  hydrateImmediateHydratedStores,
  renderOrHydrateAllComponents,
  renderOrHydrateImmediateHydratedComponents,
  unmountAll,
} from './pro/ClientSideRenderer.js';
import { onPageLoaded, onPageUnloaded } from './pageLifecycle.js';
import { debugTurbolinks } from './turbolinksUtils.js';

export async function reactOnRailsPageLoaded() {
  debugTurbolinks('reactOnRailsPageLoaded');
  await Promise.all([hydrateAllStores(), renderOrHydrateAllComponents()]);
}
function reactOnRailsPageUnloaded() {
  debugTurbolinks('reactOnRailsPageUnloaded');
  unmountAll();
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
  // Force loaded components and stores are rendered and hydrated immediately.
  // The hydration process can handle the concurrent hydration of components and stores,
  // so awaiting this isn't necessary.
  void renderOrHydrateImmediateHydratedComponents();
  void hydrateImmediateHydratedStores();
  // Other components and stores are rendered and hydrated when the page is fully loaded
  onPageLoaded(reactOnRailsPageLoaded);
  onPageUnloaded(reactOnRailsPageUnloaded);
}
