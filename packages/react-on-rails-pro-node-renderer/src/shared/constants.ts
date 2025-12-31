/**
 * Size limits for HTTP request handling.
 * Used by both Fastify configuration and NDJSON stream processing.
 */

/** Maximum total request body size (100MB) */
export const BODY_SIZE_LIMIT = 100 * 1024 * 1024;

/** Maximum single field/line size (10MB) - used for form fields and NDJSON lines */
export const FIELD_SIZE_LIMIT = 10 * 1024 * 1024;
