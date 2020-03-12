/**
 * Get the context, be it window or global
 * @returns {boolean|Window|*|context}
 */
export default function context(): Window | NodeJS.Global | undefined {
  return ((typeof window !== 'undefined') && window) ||
    ((typeof global !== 'undefined') && global) ||
    this;
}
