import type { ResponseResult } from '../shared/utils';
/**
 * Error thrown when waiting for a stream chunk times out.
 */
export declare class StreamChunkTimeoutError extends Error {
    constructor(timeoutMs: number);
}
/**
 * Result interface for render request callbacks
 */
export interface RenderRequestResult {
    response: ResponseResult;
    shouldContinue: boolean;
}
/**
 * Options interface for incremental render stream handler
 */
export interface IncrementalRenderStreamHandlerOptions {
    request: {
        raw: NodeJS.ReadableStream | {
            [Symbol.asyncIterator](): AsyncIterator<Buffer>;
        };
    };
    onRenderRequestReceived: (renderRequest: unknown) => Promise<RenderRequestResult> | RenderRequestResult;
    onResponseStart: (response: ResponseResult) => Promise<void> | void;
    onUpdateReceived: (updateData: unknown) => Promise<void> | void;
    onRequestEnded: () => Promise<void> | void;
}
/**
 * Handles incremental rendering requests with streaming JSON data.
 * The first object triggers rendering, subsequent objects provide incremental updates.
 */
export declare function handleIncrementalRenderStream(options: IncrementalRenderStreamHandlerOptions): Promise<void>;
//# sourceMappingURL=handleIncrementalRenderStream.d.ts.map