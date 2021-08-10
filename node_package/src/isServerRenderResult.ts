import type { CreateReactOutputResult, ServerRenderResult } from './types/index';

export function isServerRenderHash(testValue: CreateReactOutputResult):
  testValue is ServerRenderResult {
  return !!(
    (testValue as ServerRenderResult).renderedHtml ||
    (testValue as ServerRenderResult).redirectLocation ||
    (testValue as ServerRenderResult).routeError ||
    (testValue as ServerRenderResult).error);
}

export function isPromise(testValue: CreateReactOutputResult):
  testValue is Promise<string> {
  return !!((testValue as Promise<string>).then);
}
