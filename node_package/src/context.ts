import type { ReactOnRails as ReactOnRailsType } from './types';

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
  return ((typeof window !== 'undefined') && window) ||
    ((typeof global !== 'undefined') && global) ||
    this;
}


export function reactOnRailsContext(): Context {
  const ctx = context();
  if (ctx === undefined || typeof ctx.ReactOnRails === 'undefined') {
    throw new Error('ReactOnRails is undefined in both global and window namespaces.');
  }
  return ctx;
}
