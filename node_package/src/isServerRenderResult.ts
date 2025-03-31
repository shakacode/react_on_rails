import type { CreateReactOutputResult, ServerRenderResult, RenderFunctionResult } from './types/index';

export function isServerRenderHash(
  testValue: CreateReactOutputResult | RenderFunctionResult,
): testValue is ServerRenderResult {
  return !!(
    (testValue as ServerRenderResult).renderedHtml ||
    (testValue as ServerRenderResult).redirectLocation ||
    (testValue as ServerRenderResult).routeError ||
    (testValue as ServerRenderResult).error
  );
}

export function isPromise<T>(
  testValue: CreateReactOutputResult | RenderFunctionResult | Promise<T> | string | null,
): testValue is Promise<T> {
  return !!(testValue as Promise<T> | null)?.then;
}
