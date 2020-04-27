import type { CreateReactOutputResult, ServerRenderResult } from './types/index';

export default function isServerRenderResult(testValue: CreateReactOutputResult):
  testValue is ServerRenderResult {
  return !!(
    (testValue as ServerRenderResult).renderedHtml ||
    (testValue as ServerRenderResult).redirectLocation ||
    (testValue as ServerRenderResult).routeError ||
    (testValue as ServerRenderResult).error);
}

