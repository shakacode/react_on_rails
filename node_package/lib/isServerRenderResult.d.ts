import type {
  CreateReactOutputResult,
  ServerRenderResult,
  RenderFunctionResult,
  RenderStateHtml,
} from './types/index.ts';

export declare function isServerRenderHash(
  testValue: CreateReactOutputResult | RenderFunctionResult,
): testValue is ServerRenderResult;
export declare function isPromise<T>(
  testValue: CreateReactOutputResult | RenderFunctionResult | Promise<T> | RenderStateHtml | string | null,
): testValue is Promise<T>;
