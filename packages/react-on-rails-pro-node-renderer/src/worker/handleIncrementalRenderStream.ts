import { StringDecoder } from 'string_decoder';
import type { ResponseResult } from '../shared/utils';
import * as errorReporter from '../shared/errorReporter';
import { BODY_SIZE_LIMIT, FIELD_SIZE_LIMIT, STREAM_CHUNK_TIMEOUT_MS } from '../shared/constants';
import log from '../shared/log';

/**
 * Error thrown when waiting for a stream chunk times out.
 */
export class StreamChunkTimeoutError extends Error {
  constructor(timeoutMs: number) {
    super(`Timed out waiting for next chunk after ${timeoutMs}ms. The client may have disconnected or stopped sending data.`);
    this.name = 'StreamChunkTimeoutError';
  }
}

/**
 * Wraps an async iterator with a timeout for each chunk.
 * If no chunk is received within the timeout, throws StreamChunkTimeoutError.
 */
async function* withChunkTimeout<T>(
  iterator: AsyncIterable<T>,
  timeoutMs: number,
): AsyncGenerator<T, void, undefined> {
  const asyncIterator = iterator[Symbol.asyncIterator]();

  while (true) {
    let timeoutId: NodeJS.Timeout | undefined;

    try {
      // eslint-disable-next-line no-await-in-loop
      const result = await Promise.race([
        asyncIterator.next(),
        new Promise<never>((_, reject) => {
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
    } catch (err) {
      // Clear timeout on error to prevent memory leaks
      if (timeoutId) {
        clearTimeout(timeoutId);
      }
      throw err;
    }
  }
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
  let onResponseStartPromise: Promise<void> | null = null;

  try {
    log.debug('Starting to handle incremental render stream');
    for await (const chunk of withChunkTimeout(request.raw as AsyncIterable<Buffer>, STREAM_CHUNK_TIMEOUT_MS)) {
      log.debug(`Received chunk of size ${chunk.length}`);
      const chunkBuffer = chunk instanceof Buffer ? chunk : Buffer.from(chunk);
      totalBytesReceived += chunkBuffer.length;

      // Check total request size limit
      if (totalBytesReceived > BODY_SIZE_LIMIT) {
        throw new Error(
          `NDJSON request exceeds maximum size of ${BODY_SIZE_LIMIT} bytes (${Math.round(BODY_SIZE_LIMIT / 1024 / 1024)}MB). ` +
            `Received ${totalBytesReceived} bytes.`,
        );
      }

      const str = decoder.write(chunkBuffer);
      buffer += str;

      // Check single line size limit (protects against missing newlines)
      if (buffer.length > FIELD_SIZE_LIMIT) {
        throw new Error(
          `NDJSON line exceeds maximum size of ${FIELD_SIZE_LIMIT} bytes (${Math.round(FIELD_SIZE_LIMIT / 1024 / 1024)}MB). ` +
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

              onResponseStartPromise = Promise.resolve(onResponseStart(response));

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
      log.debug('Finished processing current chunk');
    }

    log.debug('Finished reading incremental render stream');
  } catch (err) {
    const error = err instanceof Error ? err : new Error(String(err));
    // Update the error message in place to retain the original stack trace, rather than creating a new error object
    error.message = `Error while handling the request stream: ${error.message}`;
    throw error;
  } finally {
    log.debug('Finalizing incremental render stream handling');
  }

  // Stream ended normally
  await onRequestEnded();
  await onResponseStartPromise;
}
