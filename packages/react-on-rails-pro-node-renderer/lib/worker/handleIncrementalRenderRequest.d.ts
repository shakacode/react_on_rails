import type { ResponseResult } from '../shared/utils';
export type IncrementalRenderSink = {
    /** Called for every subsequent NDJSON object after the first one */
    add: (chunk: unknown) => Promise<void>;
    handleRequestClosed: () => void;
};
export type UpdateChunk = {
    bundleTimestamp: string | number;
    updateChunk: string;
};
export type IncrementalRenderInitialRequest = {
    firstRequestChunk: unknown;
    bundleTimestamp: string | number;
    dependencyBundleTimestamps?: string[] | number[];
};
export type FirstIncrementalRenderRequestChunk = {
    renderingRequest: string;
    onRequestClosedUpdateChunk?: UpdateChunk;
};
export type IncrementalRenderResult = {
    response: ResponseResult;
    sink?: IncrementalRenderSink;
};
/**
 * Handles the initial request for incremental rendering and returns a "sink" for updates.
 *
 * ARCHITECTURE: Incremental rendering uses a "sink" pattern for update chunks:
 *
 * 1. Initial Request Flow:
 *    Rails → NDJSON line 1 → handleIncrementalRenderRequest → VM executes renderingRequest
 *    └── Creates AsyncPropsManager, stores in sharedExecutionContext
 *    └── React component suspends on asyncPropsManager.getProp("propName")
 *    └── Returns streaming response (initial shell HTML)
 *
 * 2. Update Chunk Flow (for each async prop):
 *    Rails → NDJSON line N → sink.add(chunk) → VM executes updateChunk
 *    └── updateChunk calls asyncPropsManager.setProp("propName", value)
 *    └── React promise resolves, component resumes rendering
 *    └── More HTML chunks stream back
 *
 * 3. Stream End Flow:
 *    Rails closes HTTP request → sink.handleRequestClosed()
 *    └── Executes onRequestClosedUpdateChunk (calls asyncPropsManager.endStream())
 *    └── Any unresolved props reject with error
 *
 * The sink uses the SAME ExecutionContext created during initial request,
 * so update chunks can access sharedExecutionContext.get("asyncPropsManager").
 *
 * @returns response - The initial render result (streaming HTML)
 * @returns sink - Object with add() and handleRequestClosed() for processing updates
 */
export declare function handleIncrementalRenderRequest(initial: IncrementalRenderInitialRequest): Promise<IncrementalRenderResult>;
export type { ResponseResult };
//# sourceMappingURL=handleIncrementalRenderRequest.d.ts.map