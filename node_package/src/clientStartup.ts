import { type Context, isWindow } from './context';
import {
  renderOrHydrateForceLoadedComponents,
  renderOrHydrateAllComponents,
  hydrateForceLoadedStores,
  hydrateAllStores,
  unmountAll,
} from './ClientSideRenderer';
import { onPageLoaded, onPageUnloaded } from './pageLifecycle';
import { debugTurbolinks } from './turbolinksUtils';

export function reactOnRailsPageLoaded(): void {
  debugTurbolinks('reactOnRailsPageLoaded');
  hydrateAllStores();
  renderOrHydrateAllComponents();
}

function reactOnRailsPageUnloaded(): void {
  debugTurbolinks('reactOnRailsPageUnloaded');
  unmountAll();
}

export async function clientStartup(context: Context): Promise<void> {
  await new Promise((resolve) => setTimeout(resolve, 4000));
  // Check if server rendering
  if (!isWindow(context)) {
    return;
  }

  // Tried with a file local variable, but the install handler gets called twice.
  // eslint-disable-next-line no-underscore-dangle
  if (context.__REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__) {
    return;
  }

  // eslint-disable-next-line no-underscore-dangle, no-param-reassign
  context.__REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__ = true;

  // force loaded components and stores are rendered and hydrated immediately
  renderOrHydrateForceLoadedComponents();
  hydrateForceLoadedStores();

  // Other components and stores are rendered and hydrated when the page is fully loaded
  onPageLoaded(reactOnRailsPageLoaded);
  onPageUnloaded(reactOnRailsPageUnloaded);
}
