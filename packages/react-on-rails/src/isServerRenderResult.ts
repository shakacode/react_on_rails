import type {
  CreateReactOutputResult,
  ServerRenderResult,
  RenderFunctionResult,
  RenderStateHtml,
} from './types/index.ts';

export function isServerRenderHash(testValue: unknown): testValue is ServerRenderResult {
  if (!testValue || typeof testValue !== 'object') {
    return false;
  }

  return (
    'renderedHtml' in testValue ||
    'redirectLocation' in testValue ||
    'routeError' in testValue ||
    'error' in testValue
  );
}

export function isPromise<T>(
  testValue: CreateReactOutputResult | RenderFunctionResult | Promise<T> | RenderStateHtml | string | null,
): testValue is Promise<T> {
  return !!(testValue as Promise<T> | null)?.then;
}
