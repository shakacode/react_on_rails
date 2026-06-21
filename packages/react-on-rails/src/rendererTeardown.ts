import type { RendererTeardownResult } from './types/index.ts';

// Shared type guard for RendererTeardownResult, extracted so OSS and Pro can import it without
// duplicating the predicate or coupling Pro to ClientRenderer internals.
// eslint-disable-next-line import/prefer-default-export -- single-export module; named export keeps the type guard's API tied to its predicate name.
export function isRendererTeardownResult(value: unknown): value is RendererTeardownResult {
  return (
    value != null &&
    typeof value === 'object' &&
    typeof (value as { teardown?: unknown }).teardown === 'function'
  );
}
