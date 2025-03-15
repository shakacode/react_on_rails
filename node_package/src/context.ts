import type { ReactOnRails as ReactOnRailsType, RailsContext } from './types';

declare global {
  interface Window {
    ReactOnRails: ReactOnRailsType;
    __REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__?: boolean;
  }

  namespace globalThis {
    /* eslint-disable no-var,vars-on-top */
    var ReactOnRails: ReactOnRailsType;
    /* eslint-enable no-var,vars-on-top */
  }
}

export type Context = Window | typeof globalThis;

/**
 * Get the context, be it window or global
 */
export default function context(this: void): Context | void {
  return (typeof window !== 'undefined' && window) || (typeof global !== 'undefined' && global) || this;
}

export function isWindow(ctx: Context): ctx is Window {
  return (ctx as Window).document !== undefined;
}

export function reactOnRailsContext(): Context {
  const ctx = context();
  if (ctx === undefined || typeof ctx.ReactOnRails === 'undefined') {
    throw new Error('ReactOnRails is undefined in both global and window namespaces.');
  }
  return ctx;
}

let currentContext: Context | null = null;
let currentRailsContext: RailsContext | null = null;

// caches context and railsContext to avoid re-parsing rails-context each time a component is rendered
// Cached values will be reset when resetContextAndRailsContext() is called
export function getContextAndRailsContext(): { context: Context | null; railsContext: RailsContext | null } {
  // Return cached values if already set
  if (currentContext && currentRailsContext) {
    return { context: currentContext, railsContext: currentRailsContext };
  }

  currentContext = reactOnRailsContext();

  const el = document.getElementById('js-react-on-rails-context');
  if (!el || !el.textContent) {
    return { context: null, railsContext: null };
  }

  try {
    currentRailsContext = JSON.parse(el.textContent) as RailsContext;
  } catch (e) {
    console.error('Error parsing Rails context:', e);
    return { context: null, railsContext: null };
  }

  return { context: currentContext, railsContext: currentRailsContext };
}

export function resetContextAndRailsContext(): void {
  currentContext = null;
  currentRailsContext = null;
}
