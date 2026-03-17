/**
 * Size limits for HTTP request handling.
 * Used by both Fastify configuration and NDJSON stream processing.
 */
/** Maximum total request body size (100MB) */
export declare const BODY_SIZE_LIMIT: number;
/** Maximum single field/line size (10MB) - used for form fields and NDJSON lines */
export declare const FIELD_SIZE_LIMIT: number;
/**
 * Timeout in milliseconds for waiting for the next chunk in an incremental render stream.
 * If no chunk is received within this timeout, the request is cancelled.
 * This prevents requests from hanging forever when clients disconnect without properly closing the stream.
 */
export declare const STREAM_CHUNK_TIMEOUT_MS: number;
//# sourceMappingURL=constants.d.ts.map