import type { CreateReactOutputResult, ServerRenderResult } from './types/index';
export declare function isServerRenderHash(testValue: CreateReactOutputResult): testValue is ServerRenderResult;
export declare function isPromise(testValue: CreateReactOutputResult): testValue is Promise<string>;
