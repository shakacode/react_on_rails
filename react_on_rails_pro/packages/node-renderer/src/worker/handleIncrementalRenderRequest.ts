import type { ResponseResult } from '../shared/utils';
import { handleRenderRequest } from './handleRenderRequest';

export type IncrementalRenderSink = {
  /** Called for every subsequent NDJSON object after the first one */
  add: (chunk: unknown) => void;
  /** Called when the client finishes sending the NDJSON stream */
  end: () => void;
  /** Called if the request stream errors or validation fails */
  abort: (error: unknown) => void;
};

export type IncrementalRenderInitialRequest = {
  renderingRequest: string;
  bundleTimestamp: string | number;
  dependencyBundleTimestamps?: string[] | number[];
};

export type IncrementalRenderResult = {
  response: ResponseResult;
  sink: IncrementalRenderSink;
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
    const renderResult = await handleRenderRequest({
      renderingRequest,
      bundleTimestamp,
      dependencyBundleTimestamps,
      providedNewBundles: undefined,
      assetsToCopy: undefined,
    });

    // Return the result directly with a placeholder sink
    return {
      response: renderResult,
      sink: {
        add: () => {
          /* no-op - will be implemented in next commit */
        },
        end: () => {
          /* no-op - will be implemented in next commit */
        },
        abort: () => {
          /* no-op - will be implemented in next commit */
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
      sink: {
        add: () => {
          /* no-op */
        },
        end: () => {
          /* no-op */
        },
        abort: () => {
          /* no-op */
        },
      },
    };
  }
}

export type { ResponseResult };
