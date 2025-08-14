import { StringDecoder } from 'string_decoder';
import type { ResponseResult } from '../shared/utils';

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
  onResponseStart: (response: ResponseResult) => Promise<void> | undefined;
  onUpdateReceived: (updateData: unknown) => Promise<void> | undefined;
  onRequestEnded: () => Promise<void> | undefined;
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

  try {
    for await (const chunk of request.raw) {
      const str = decoder.write(chunk);
      buffer += str;

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
            throw new Error(`Invalid JSON chunk: ${err instanceof Error ? err.message : String(err)}`);
          }

          if (!hasReceivedFirstObject) {
            hasReceivedFirstObject = true;
            // eslint-disable-next-line no-await-in-loop
            const result = await onRenderRequestReceived(parsed);
            const { response, shouldContinue: continueFlag } = result;

            // eslint-disable-next-line no-await-in-loop
            await onResponseStart(response);

            if (!continueFlag) {
              return;
            }
          } else {
            // eslint-disable-next-line no-await-in-loop
            await onUpdateReceived(parsed);
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
  await onRequestEnded();
}
