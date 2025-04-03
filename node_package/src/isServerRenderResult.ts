import type { CreateReactOutputResult, ServerRenderResult } from './types/index.ts';

export function isServerRenderHash(testValue: CreateReactOutputResult): testValue is ServerRenderResult {
  return !!(
    (testValue as ServerRenderResult).renderedHtml ||
    (testValue as ServerRenderResult).redirectLocation ||
    (testValue as ServerRenderResult).routeError ||
    (testValue as ServerRenderResult).error
  );
}

export function isPromise<T>(
  testValue: CreateReactOutputResult | Promise<T> | string | null,
): testValue is Promise<T> {
  return !!(testValue as Promise<T> | null)?.then;
}
