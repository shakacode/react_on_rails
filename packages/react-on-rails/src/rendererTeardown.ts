import type { RendererTeardownResult } from './types/index.ts';

// eslint-disable-next-line import/prefer-default-export -- internal teardown helpers should use named imports.
export function isRendererTeardownResult(value: unknown): value is RendererTeardownResult {
  return (
    value != null &&
    typeof value === 'object' &&
    typeof (value as { teardown?: unknown }).teardown === 'function'
  );
}
