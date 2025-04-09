import type { ReactOnRailsInternal, RailsContext } from './types';

declare global {
  /* eslint-disable no-var,vars-on-top,no-underscore-dangle */
  var ReactOnRails: ReactOnRailsInternal;
  var __REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__: boolean;
  /* eslint-enable no-var,vars-on-top,no-underscore-dangle */
}

let currentRailsContext: RailsContext | null = null;

// caches context and railsContext to avoid re-parsing rails-context each time a component is rendered
// Cached values will be reset when resetRailsContext() is called
export function getRailsContext(): { railsContext: RailsContext | null } {
  // Return cached values if already set
  if (currentRailsContext) {
    return { railsContext: currentRailsContext };
  }

  const el = document.getElementById('js-react-on-rails-context');
  if (!el?.textContent) {
    return { railsContext: null };
  }

  try {
    currentRailsContext = JSON.parse(el.textContent) as RailsContext;
  } catch (e) {
    console.error('Error parsing Rails context:', e);
    return { railsContext: null };
  }

  return { railsContext: currentRailsContext };
}

export function resetRailsContext(): void {
  currentRailsContext = null;
}
