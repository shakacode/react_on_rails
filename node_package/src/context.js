/**
 * Get the context, be it window or global
 * @returns {boolean|Window|*|context}
 */
export default function context() {
  return ((typeof window !== 'undefined') && window) ||
    ((typeof global !== 'undefined') && global) ||
    this;
}
