import type { ResponseResult } from '../shared/utils';
import { handleRenderRequest } from './handleRenderRequest';
import log from '../shared/log';
import { getRequestBundleFilePath, isErrorRenderResult } from '../shared/utils';
import { subSpan } from '../shared/tracing.js';

export type IncrementalRenderSink = {
  /** Called for every subsequent NDJSON object after the first one */
  add: (chunk: unknown) => Promise<void>;
  handleRequestClosed: () => void;
};

export type UpdateChunk = {
  bundleTimestamp: string | number;
  updateChunk: string;
};

class InvalidIncrementalRenderChunkError extends Error {
  constructor() {
    super('Invalid incremental render chunk received, missing properties');
    this.name = 'InvalidIncrementalRenderChunkError';
  }
}

function assertIsUpdateChunk(value: unknown): asserts value is UpdateChunk {
  if (
    typeof value !== 'object' ||
    value === null ||
    !('bundleTimestamp' in value) ||
    !('updateChunk' in value) ||
    (typeof value.bundleTimestamp !== 'string' && typeof value.bundleTimestamp !== 'number') ||
    typeof value.updateChunk !== 'string'
  ) {
    throw new InvalidIncrementalRenderChunkError();
  }
}

export type IncrementalRenderInitialRequest = {
  firstRequestChunk: unknown;
  bundleTimestamp: string | number;
  dependencyBundleTimestamps?: string[] | number[];
};

export type FirstIncrementalRenderRequestChunk = {
  renderingRequest: string;
  onRequestClosedUpdateChunk?: UpdateChunk;
};

function assertFirstIncrementalRenderRequestChunk(
  chunk: unknown,
): asserts chunk is FirstIncrementalRenderRequestChunk {
  if (
    typeof chunk !== 'object' ||
    chunk === null ||
    !('renderingRequest' in chunk) ||
    typeof chunk.renderingRequest !== 'string'
  ) {
    throw new Error('Invalid first incremental render request chunk received, missing properties');
  }

  // Validate onRequestClosedUpdateChunk if present (optional field)
  if ('onRequestClosedUpdateChunk' in chunk && chunk.onRequestClosedUpdateChunk) {
    assertIsUpdateChunk(chunk.onRequestClosedUpdateChunk);
  }
}

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
export async function handleIncrementalRenderRequest(
  initial: IncrementalRenderInitialRequest,
): Promise<IncrementalRenderResult> {
  const { firstRequestChunk, bundleTimestamp, dependencyBundleTimestamps } = initial;
  assertFirstIncrementalRenderRequestChunk(firstRequestChunk);
  const { renderingRequest, onRequestClosedUpdateChunk } = firstRequestChunk;

  try {
    // Call handleRenderRequest internally to handle all validation and VM execution
    // Incremental requests do not enter through worker.ts's trace() wrapper, so
    // there is no tracingContext to forward for handleRenderRequest's error path.
    const { response, executionContext } = await handleRenderRequest({
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
        add: async (chunk: unknown) => {
          try {
            assertIsUpdateChunk(chunk);
            await subSpan({ name: 'ror.incremental.process_chunk' }, async () => {
              const bundlePath = getRequestBundleFilePath(chunk.bundleTimestamp);
              const result = await executionContext.runInVM(chunk.updateChunk, bundlePath);
              if (isErrorRenderResult(result)) {
                throw new Error(result.exceptionMessage);
              }
            });
          } catch (err) {
            if (err instanceof InvalidIncrementalRenderChunkError) {
              log.error({ msg: 'Invalid incremental render chunk', err, chunk });
            } else {
              log.error({ msg: 'Error running incremental render chunk', err, chunk });
            }
          }
        },
        handleRequestClosed: () => {
          if (!onRequestClosedUpdateChunk) {
            return;
          }

          const bundlePath = getRequestBundleFilePath(onRequestClosedUpdateChunk.bundleTimestamp);
          executionContext
            .runInVM(onRequestClosedUpdateChunk.updateChunk, bundlePath)
            .catch((err: unknown) => {
              log.error({
                msg: 'Error running onRequestClosedUpdateChunk',
                err,
                onRequestClosedUpdateChunk,
              });
            });
        },
      },
    };
  } catch (error) {
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

export type { ResponseResult };
