/**
 * Marks a registered component as an RSC (React Server Components) wrapper so callers can
 * decide whether to support it. Used by:
 *   - Pro `registerServerComponent` to tag wrapped functions.
 *   - Pro `ppr_react_component` (PPR) to refuse RSC components in v1 (RSC + PPR composition
 *     is intentionally deferred).
 *
 * Symbol.for is used so the marker is stable across module boundaries / multiple package
 * instances (e.g. when the OSS package is loaded both from a host and a yalc-linked copy).
 */
export const RSC_COMPONENT_MARKER = Symbol.for('react_on_rails_pro.rsc_component');

export function markAsRSCComponent<T extends object | ((...args: unknown[]) => unknown)>(value: T): T {
  Object.defineProperty(value, RSC_COMPONENT_MARKER, {
    value: true,
    enumerable: false,
    configurable: false,
    writable: false,
  });
  return value;
}

export function isRSCComponent(value: unknown): boolean {
  // typeof a function is 'function', not 'object' — accept both.
  return (
    !!value &&
    (typeof value === 'function' || typeof value === 'object') &&
    (value as { [k: symbol]: unknown })[RSC_COMPONENT_MARKER] === true
  );
}
