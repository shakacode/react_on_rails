import type { RailsContext } from './types';

let currentRailsContext: RailsContext | null = null;

// caches context and railsContext to avoid re-parsing rails-context each time a component is rendered
// Cached values will be reset when resetRailsContext() is called
export function getRailsContext(): RailsContext | null {
  // Return cached values if already set
  if (currentRailsContext) {
    return currentRailsContext;
  }

  const el = document.getElementById('js-react-on-rails-context');
  if (!el?.textContent) {
    return null;
  }

  try {
    currentRailsContext = JSON.parse(el.textContent) as RailsContext;
    return currentRailsContext;
  } catch (e) {
    console.error('Error parsing Rails context:', e);
    return null;
  }
}

export function resetRailsContext(): void {
  currentRailsContext = null;
}
