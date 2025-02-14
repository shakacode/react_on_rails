export type Context = Window | typeof globalThis;

/**
 * Get the context, be it window or global
 */
export default function context(this: void): Context | void {
  return ((typeof window !== 'undefined') && window) ||
    ((typeof global !== 'undefined') && global) ||
    globalThis;
}
