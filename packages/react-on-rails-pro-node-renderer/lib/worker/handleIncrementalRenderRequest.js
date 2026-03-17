"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.handleIncrementalRenderRequest = handleIncrementalRenderRequest;
const handleRenderRequest_1 = require("./handleRenderRequest");
const log_1 = __importDefault(require("../shared/log"));
const utils_1 = require("../shared/utils");
function assertIsUpdateChunk(value) {
    if (typeof value !== 'object' ||
        value === null ||
        !('bundleTimestamp' in value) ||
        !('updateChunk' in value) ||
        (typeof value.bundleTimestamp !== 'string' && typeof value.bundleTimestamp !== 'number') ||
        typeof value.updateChunk !== 'string') {
        throw new Error('Invalid incremental render chunk received, missing properties');
    }
}
function assertFirstIncrementalRenderRequestChunk(chunk) {
    if (typeof chunk !== 'object' ||
        chunk === null ||
        !('renderingRequest' in chunk) ||
        typeof chunk.renderingRequest !== 'string') {
        throw new Error('Invalid first incremental render request chunk received, missing properties');
    }
    // Validate onRequestClosedUpdateChunk if present (optional field)
    if ('onRequestClosedUpdateChunk' in chunk && chunk.onRequestClosedUpdateChunk) {
        assertIsUpdateChunk(chunk.onRequestClosedUpdateChunk);
    }
}
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
async function handleIncrementalRenderRequest(initial) {
    const { firstRequestChunk, bundleTimestamp, dependencyBundleTimestamps } = initial;
    assertFirstIncrementalRenderRequestChunk(firstRequestChunk);
    const { renderingRequest, onRequestClosedUpdateChunk } = firstRequestChunk;
    try {
        // Call handleRenderRequest internally to handle all validation and VM execution
        const { response, executionContext } = await (0, handleRenderRequest_1.handleRenderRequest)({
            renderingRequest,
            bundleTimestamp,
            dependencyBundleTimestamps,
            providedNewBundles: undefined,
            assetsToCopy: undefined,
        });
        // If we don't get an execution context, it means there was an early error
        // (e.g. bundle not found). In this case, the sink will be a no-op.
        if (!executionContext) {
            return { response };
        }
        // Return the result with a sink that uses the execution context
        return {
            response,
            sink: {
                add: async (chunk) => {
                    try {
                        assertIsUpdateChunk(chunk);
                        const bundlePath = (0, utils_1.getRequestBundleFilePath)(chunk.bundleTimestamp);
                        await executionContext.runInVM(chunk.updateChunk, bundlePath).catch((err) => {
                            log_1.default.error({ msg: 'Error running incremental render chunk', err, chunk });
                        });
                    }
                    catch (err) {
                        log_1.default.error({ msg: 'Invalid incremental render chunk', err, chunk });
                    }
                },
                handleRequestClosed: () => {
                    if (!onRequestClosedUpdateChunk) {
                        return;
                    }
                    const bundlePath = (0, utils_1.getRequestBundleFilePath)(onRequestClosedUpdateChunk.bundleTimestamp);
                    executionContext
                        .runInVM(onRequestClosedUpdateChunk.updateChunk, bundlePath)
                        .catch((err) => {
                        log_1.default.error({
                            msg: 'Error running onRequestClosedUpdateChunk',
                            err,
                            onRequestClosedUpdateChunk,
                        });
                    });
                },
            },
        };
    }
    catch (error) {
        // Handle any unexpected errors
        const errorMessage = error instanceof Error ? error.message : String(error);
        return {
            response: {
                status: 500,
                headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
                data: errorMessage,
            },
        };
    }
}
//# sourceMappingURL=handleIncrementalRenderRequest.js.map