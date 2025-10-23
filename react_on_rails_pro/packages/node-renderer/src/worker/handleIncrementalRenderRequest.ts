import type { ResponseResult } from '../shared/utils';
import { handleRenderRequest } from './handleRenderRequest';
import log from '../shared/log';
import { getRequestBundleFilePath } from '../shared/utils';

export type IncrementalRenderSink = {
  /** Called for every subsequent NDJSON object after the first one */
  add: (chunk: unknown) => void;
};

export type UpdateChunk = {
  bundleTimestamp: string | number;
  updateChunk: string;
};

function assertIsUpdateChunk(value: unknown): asserts value is UpdateChunk {
  if (
    typeof value !== 'object' ||
    value === null ||
    !('bundleTimestamp' in value) ||
    !('updateChunk' in value) ||
    (typeof value.bundleTimestamp !== 'string' && typeof value.bundleTimestamp !== 'number') ||
    typeof value.updateChunk !== 'string'
  ) {
    throw new Error('Invalid incremental render chunk received, missing properties');
  }
}

export type IncrementalRenderInitialRequest = {
  renderingRequest: string;
  bundleTimestamp: string | number;
  dependencyBundleTimestamps?: string[] | number[];
};

export type IncrementalRenderResult = {
  response: ResponseResult;
  sink?: IncrementalRenderSink;
};

/**
 * Starts handling an incremental render request. This function:
 * - Calls handleRenderRequest internally to handle all validation and VM execution
 * - Returns the result from handleRenderRequest directly
 * - Provides a sink for future incremental updates (to be implemented in next commit)
 */
export async function handleIncrementalRenderRequest(
  initial: IncrementalRenderInitialRequest,
): Promise<IncrementalRenderResult> {
  const { renderingRequest, bundleTimestamp, dependencyBundleTimestamps } = initial;

  try {
    // Call handleRenderRequest internally to handle all validation and VM execution
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
        add: (chunk: unknown) => {
          try {
            assertIsUpdateChunk(chunk);
            const bundlePath = getRequestBundleFilePath(chunk.bundleTimestamp);
            executionContext.runInVM(chunk.updateChunk, bundlePath).catch((err: unknown) => {
              log.error({ msg: 'Error running incremental render chunk', err, chunk });
            });
          } catch (err) {
            log.error({ msg: 'Invalid incremental render chunk', err, chunk });
          }
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
