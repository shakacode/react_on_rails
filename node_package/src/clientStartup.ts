import {
  hydrateAllStores,
  hydrateForceLoadedStores,
  renderOrHydrateAllComponents,
  renderOrHydrateForceLoadedComponents,
  unmountAll,
} from './pro/ClientSideRenderer.ts';
import { onPageLoaded, onPageUnloaded } from './pageLifecycle.ts';
import { debugTurbolinks } from './turbolinksUtils.ts';

export async function reactOnRailsPageLoaded() {
  debugTurbolinks('reactOnRailsPageLoaded');
  await Promise.all([hydrateAllStores(), renderOrHydrateAllComponents()]);
}

function reactOnRailsPageUnloaded(): void {
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
  void renderOrHydrateForceLoadedComponents();
  void hydrateForceLoadedStores();

  // Other components and stores are rendered and hydrated when the page is fully loaded
  onPageLoaded(reactOnRailsPageLoaded);
  onPageUnloaded(reactOnRailsPageUnloaded);
}
