import type { ServerRenderResult } from './types/index.ts';

export function isServerRenderHash(testValue: unknown): testValue is ServerRenderResult {
  if (!testValue || typeof testValue !== 'object') {
    return false;
  }

  const hasPrimaryServerRenderKey =
    'renderedHtml' in testValue ||
    'redirectLocation' in testValue ||
    'routeError' in testValue ||
    'error' in testValue;
  return hasPrimaryServerRenderKey;
}

export function isPromise<T>(testValue: unknown): testValue is Promise<T> {
  return !!(testValue as Promise<T> | null)?.then;
}
