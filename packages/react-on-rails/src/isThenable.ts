/* eslint-disable import/prefer-default-export -- named export for grep-ability and consistency with other @internal helpers */

/**
 * Narrows an unknown value to a thenable (has a callable `.then`) without assuming a native
 * Promise. Shared by the core ClientRenderer, rootErrorHandlers, and the Pro ClientSideRenderer
 * (via `react-on-rails/@internal/isThenable`) so non-native thenables are handled identically
 * everywhere.
 */
export function isThenable(value: unknown): value is PromiseLike<unknown> {
  return (
    value != null &&
    (typeof value === 'object' || typeof value === 'function') &&
    typeof (value as { then?: unknown }).then === 'function'
  );
}
