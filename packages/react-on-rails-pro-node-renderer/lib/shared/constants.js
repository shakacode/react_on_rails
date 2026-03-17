"use strict";
/**
 * Size limits for HTTP request handling.
 * Used by both Fastify configuration and NDJSON stream processing.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.STREAM_CHUNK_TIMEOUT_MS = exports.FIELD_SIZE_LIMIT = exports.BODY_SIZE_LIMIT = void 0;
/** Maximum total request body size (100MB) */
exports.BODY_SIZE_LIMIT = 100 * 1024 * 1024;
/** Maximum single field/line size (10MB) - used for form fields and NDJSON lines */
exports.FIELD_SIZE_LIMIT = 10 * 1024 * 1024;
/**
 * Timeout in milliseconds for waiting for the next chunk in an incremental render stream.
 * If no chunk is received within this timeout, the request is cancelled.
 * This prevents requests from hanging forever when clients disconnect without properly closing the stream.
 */
exports.STREAM_CHUNK_TIMEOUT_MS = 20 * 1000; // 20 seconds
//# sourceMappingURL=constants.js.map