"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.StreamChunkTimeoutError = void 0;
exports.handleIncrementalRenderStream = handleIncrementalRenderStream;
const string_decoder_1 = require("string_decoder");
const errorReporter = __importStar(require("../shared/errorReporter"));
const constants_1 = require("../shared/constants");
const log_1 = __importDefault(require("../shared/log"));
/**
 * Error thrown when waiting for a stream chunk times out.
 */
class StreamChunkTimeoutError extends Error {
    constructor(timeoutMs) {
        super(`Timed out waiting for next chunk after ${timeoutMs}ms. The client may have disconnected or stopped sending data.`);
        this.name = 'StreamChunkTimeoutError';
    }
}
exports.StreamChunkTimeoutError = StreamChunkTimeoutError;
/**
 * Wraps an async iterator with a timeout for each chunk.
 * If no chunk is received within the timeout, throws StreamChunkTimeoutError.
 */
async function* withChunkTimeout(iterator, timeoutMs) {
    const asyncIterator = iterator[Symbol.asyncIterator]();
    while (true) {
        let timeoutId;
        try {
            // eslint-disable-next-line no-await-in-loop
            const result = await Promise.race([
                asyncIterator.next(),
                new Promise((_, reject) => {
                    timeoutId = setTimeout(() => reject(new StreamChunkTimeoutError(timeoutMs)), timeoutMs);
                }),
            ]);
            // Clear timeout since we got a result
            if (timeoutId) {
                clearTimeout(timeoutId);
            }
            if (result.done) {
                return;
            }
            yield result.value;
        }
        catch (err) {
            // Clear timeout on error to prevent memory leaks
            if (timeoutId) {
                clearTimeout(timeoutId);
            }
            throw err;
        }
    }
}
/**
 * Handles incremental rendering requests with streaming JSON data.
 * The first object triggers rendering, subsequent objects provide incremental updates.
 */
async function handleIncrementalRenderStream(options) {
    const { request, onRenderRequestReceived, onResponseStart, onUpdateReceived, onRequestEnded } = options;
    let hasReceivedFirstObject = false;
    const decoder = new string_decoder_1.StringDecoder('utf8');
    let buffer = '';
    let totalBytesReceived = 0;
    let onResponseStartPromise = null;
    try {
        log_1.default.debug('Starting to handle incremental render stream');
        for await (const chunk of withChunkTimeout(request.raw, constants_1.STREAM_CHUNK_TIMEOUT_MS)) {
            log_1.default.debug(`Received chunk of size ${chunk.length}`);
            const chunkBuffer = chunk instanceof Buffer ? chunk : Buffer.from(chunk);
            totalBytesReceived += chunkBuffer.length;
            // Check total request size limit
            if (totalBytesReceived > constants_1.BODY_SIZE_LIMIT) {
                throw new Error(`NDJSON request exceeds maximum size of ${constants_1.BODY_SIZE_LIMIT} bytes (${Math.round(constants_1.BODY_SIZE_LIMIT / 1024 / 1024)}MB). ` +
                    `Received ${totalBytesReceived} bytes.`);
            }
            const str = decoder.write(chunkBuffer);
            buffer += str;
            // Check single line size limit (protects against missing newlines)
            if (buffer.length > constants_1.FIELD_SIZE_LIMIT) {
                throw new Error(`NDJSON line exceeds maximum size of ${constants_1.FIELD_SIZE_LIMIT} bytes (${Math.round(constants_1.FIELD_SIZE_LIMIT / 1024 / 1024)}MB). ` +
                    `Current buffer: ${buffer.length} bytes. Ensure each JSON object is followed by a newline.`);
            }
            // Process all complete JSON objects in the buffer
            let boundary = buffer.indexOf('\n');
            while (boundary !== -1) {
                const rawObject = buffer.slice(0, boundary).trim();
                buffer = buffer.slice(boundary + 1);
                boundary = buffer.indexOf('\n');
                if (rawObject) {
                    let parsed;
                    try {
                        parsed = JSON.parse(rawObject);
                    }
                    catch (err) {
                        const errorMessage = `Invalid JSON chunk: ${err instanceof Error ? err.message : String(err)}`;
                        if (!hasReceivedFirstObject) {
                            // Error in first chunk - throw error to stop processing
                            throw new Error(errorMessage);
                        }
                        else {
                            // Error in subsequent chunks - log and report but continue processing
                            const reportedMessage = `JSON parsing error in update chunk: ${err instanceof Error ? err.message : String(err)}`;
                            errorReporter.message(reportedMessage);
                            // Skip this malformed chunk and continue with next ones
                            // eslint-disable-next-line no-continue
                            continue;
                        }
                    }
                    if (!hasReceivedFirstObject) {
                        hasReceivedFirstObject = true;
                        try {
                            // eslint-disable-next-line no-await-in-loop
                            const result = await onRenderRequestReceived(parsed);
                            const { response, shouldContinue: continueFlag } = result;
                            onResponseStartPromise = Promise.resolve(onResponseStart(response));
                            if (!continueFlag) {
                                return;
                            }
                        }
                        catch (err) {
                            // Error in first chunk processing - throw error to stop processing
                            const error = err instanceof Error ? err : new Error(String(err));
                            error.message = `Error processing initial render request: ${error.message}`;
                            throw error;
                        }
                    }
                    else {
                        try {
                            // eslint-disable-next-line no-await-in-loop
                            await onUpdateReceived(parsed);
                        }
                        catch (err) {
                            // Error in update chunk processing - log and report but continue processing
                            const errorMessage = `Error processing update chunk: ${err instanceof Error ? err.message : String(err)}`;
                            errorReporter.message(errorMessage);
                            // Continue processing other chunks
                        }
                    }
                }
            }
            log_1.default.debug('Finished processing current chunk');
        }
        log_1.default.debug('Finished reading incremental render stream');
    }
    catch (err) {
        const error = err instanceof Error ? err : new Error(String(err));
        // Update the error message in place to retain the original stack trace, rather than creating a new error object
        error.message = `Error while handling the request stream: ${error.message}`;
        throw error;
    }
    finally {
        log_1.default.debug('Finalizing incremental render stream handling');
    }
    // Stream ended normally
    await onRequestEnded();
    await onResponseStartPromise;
}
//# sourceMappingURL=handleIncrementalRenderStream.js.map