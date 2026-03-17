/**
 * Isolates logic for handling render request. We don't want this module to
 * Fastify server and its Request and Reply objects. This allows to test
 * module in isolation and without async calls.
 * @module worker/handleRenderRequest
 */
import { Asset, ResponseResult } from '../shared/utils.js';
import { ExecutionContext } from './vm.js';
export type ProvidedNewBundle = {
    timestamp: string | number;
    bundle: Asset;
};
export declare function handleNewBundlesProvided(renderingRequest: string, providedNewBundles: ProvidedNewBundle[], assetsToCopy: Asset[] | null | undefined): Promise<ResponseResult | undefined>;
/**
 * Creates the result for the Fastify server to use.
 * @returns Promise where the result contains { status, data, headers } to
 * send back to the browser.
 */
export declare function handleRenderRequest({ renderingRequest, bundleTimestamp, dependencyBundleTimestamps, providedNewBundles, assetsToCopy, }: {
    renderingRequest: string;
    bundleTimestamp: string | number;
    dependencyBundleTimestamps?: string[] | number[];
    providedNewBundles?: ProvidedNewBundle[] | null;
    assetsToCopy?: Asset[] | null;
}): Promise<{
    response: ResponseResult;
    executionContext?: ExecutionContext;
}>;
//# sourceMappingURL=handleRenderRequest.d.ts.map