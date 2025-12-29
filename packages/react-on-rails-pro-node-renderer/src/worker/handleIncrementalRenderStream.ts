import { StringDecoder } from 'string_decoder';
import type { ResponseResult } from '../shared/utils';
import * as errorReporter from '../shared/errorReporter';

// Maximum size for a single NDJSON line (10MB - matches Fastify fieldSizeLimit)
export const MAX_NDJSON_LINE_SIZE = 10 * 1024 * 1024;

// Maximum total request size (100MB - matches Fastify bodyLimit)
export const MAX_NDJSON_REQUEST_SIZE = 100 * 1024 * 1024;

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
    raw: NodeJS.ReadableStream | { [Symbol.asyncIterator](): AsyncIterator<Buffer> };
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
export async function handleIncrementalRenderStream(
  options: IncrementalRenderStreamHandlerOptions,
): Promise<void> {
  const { request, onRenderRequestReceived, onResponseStart, onUpdateReceived, onRequestEnded } = options;

  let hasReceivedFirstObject = false;
  const decoder = new StringDecoder('utf8');
  let buffer = '';
  let totalBytesReceived = 0;

  try {
    for await (const chunk of request.raw) {
      const chunkBuffer = chunk instanceof Buffer ? chunk : Buffer.from(chunk);
      totalBytesReceived += chunkBuffer.length;

      // Check total request size limit
      if (totalBytesReceived > MAX_NDJSON_REQUEST_SIZE) {
        throw new Error(
          `NDJSON request exceeds maximum size of ${MAX_NDJSON_REQUEST_SIZE} bytes (${Math.round(MAX_NDJSON_REQUEST_SIZE / 1024 / 1024)}MB). ` +
            `Received ${totalBytesReceived} bytes.`,
        );
      }

      const str = decoder.write(chunkBuffer);
      buffer += str;

      // Check single line size limit (protects against missing newlines)
      if (buffer.length > MAX_NDJSON_LINE_SIZE) {
        throw new Error(
          `NDJSON line exceeds maximum size of ${MAX_NDJSON_LINE_SIZE} bytes (${Math.round(MAX_NDJSON_LINE_SIZE / 1024 / 1024)}MB). ` +
            `Current buffer: ${buffer.length} bytes. Ensure each JSON object is followed by a newline.`,
        );
      }

      // Process all complete JSON objects in the buffer
      let boundary = buffer.indexOf('\n');
      while (boundary !== -1) {
        const rawObject = buffer.slice(0, boundary).trim();
        buffer = buffer.slice(boundary + 1);
        boundary = buffer.indexOf('\n');

        if (rawObject) {
          let parsed: unknown;
          try {
            parsed = JSON.parse(rawObject);
          } catch (err) {
            const errorMessage = `Invalid JSON chunk: ${err instanceof Error ? err.message : String(err)}`;

            if (!hasReceivedFirstObject) {
              // Error in first chunk - throw error to stop processing
              throw new Error(errorMessage);
            } else {
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

              void onResponseStart(response);

              if (!continueFlag) {
                return;
              }
            } catch (err) {
              // Error in first chunk processing - throw error to stop processing
              const error = err instanceof Error ? err : new Error(String(err));
              error.message = `Error processing initial render request: ${error.message}`;
              throw error;
            }
          } else {
            try {
              // eslint-disable-next-line no-await-in-loop
              await onUpdateReceived(parsed);
            } catch (err) {
              // Error in update chunk processing - log and report but continue processing
              const errorMessage = `Error processing update chunk: ${err instanceof Error ? err.message : String(err)}`;
              errorReporter.message(errorMessage);
              // Continue processing other chunks
            }
          }
        }
      }
    }
  } catch (err) {
    const error = err instanceof Error ? err : new Error(String(err));
    // Update the error message in place to retain the original stack trace, rather than creating a new error object
    error.message = `Error while handling the request stream: ${error.message}`;
    throw error;
  }

  // Stream ended normally
  void onRequestEnded();
}
