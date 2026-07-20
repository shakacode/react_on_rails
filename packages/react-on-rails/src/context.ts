import type { ReactOnRailsInternal, RailsContext } from './types/index.ts';

declare global {
  /* eslint-disable vars-on-top,no-underscore-dangle */
  var ReactOnRails: ReactOnRailsInternal | undefined;
  var __REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__: boolean;
  /* eslint-enable vars-on-top,no-underscore-dangle */
}

type CachedRailsContext = {
  sourceText: string;
  value: RailsContext;
};

let railsContextCache = new WeakMap<Element, CachedRailsContext>();

// Key by source element and text so replacements and in-place morphs cannot reuse stale context.
export function getRailsContext(): RailsContext | null {
  const el = document.getElementById('js-react-on-rails-context');
  const sourceText = el?.textContent;
  if (!el || !sourceText) {
    return null;
  }

  const cachedRailsContext = railsContextCache.get(el);
  if (cachedRailsContext?.sourceText === sourceText) {
    return cachedRailsContext.value;
  }

  railsContextCache.delete(el);
  try {
    const railsContext = JSON.parse(sourceText) as RailsContext;
    railsContextCache.set(el, { sourceText, value: railsContext });
    return railsContext;
  } catch (e) {
    console.error('Error parsing Rails context:', e);
    return null;
  }
}

export function resetRailsContext(): void {
  railsContextCache = new WeakMap<Element, CachedRailsContext>();
}
