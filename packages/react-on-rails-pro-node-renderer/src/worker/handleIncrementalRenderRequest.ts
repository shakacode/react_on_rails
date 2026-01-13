import type { ResponseResult } from '../shared/utils';
import { handleRenderRequest } from './handleRenderRequest';
import { getRequestBundleFilePath } from '../shared/utils';

export type IncrementalRenderSink = {
  /** Called for every subsequent NDJSON object after the first one */
  add: (chunk: unknown) => Promise<void>;
  handleRequestClosed: () => void;
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
    console.log('[Sink] Creating incremental render sink for processing update chunks');

    return {
      response,
      sink: {
        add: async (chunk: unknown) => {
          const timestamp = new Date().toISOString();
          console.log(`[Sink] add() called at ${timestamp}`);

          try {
            assertIsUpdateChunk(chunk);
            const bundlePath = getRequestBundleFilePath(chunk.bundleTimestamp);
            console.log(`[Sink] Executing updateChunk in VM... bundlePath=${bundlePath}`);
            console.log(`[Sink] updateChunk code preview: ${chunk.updateChunk.slice(0, 150)}...`);
            await executionContext.runInVM(chunk.updateChunk, bundlePath).catch((err: unknown) => {
              console.log('[Sink] ERROR in runInVM for updateChunk:', err);
            });
            console.log('[Sink] updateChunk executed successfully');
          } catch (err) {
            console.log('[Sink] Invalid incremental render chunk:', err);
          }
        },
        handleRequestClosed: () => {
          const timestamp = new Date().toISOString();
          console.log(`[Sink] handleRequestClosed() called at ${timestamp}`);

          if (!onRequestClosedUpdateChunk) {
            console.log('[Sink] No onRequestClosedUpdateChunk provided - skipping endStream');
            return;
          }

          const bundlePath = getRequestBundleFilePath(onRequestClosedUpdateChunk.bundleTimestamp);
          console.log(
            `[Sink] Executing onRequestClosedUpdateChunk (endStream) in VM... bundlePath=${bundlePath}`,
          );
          executionContext
            .runInVM(onRequestClosedUpdateChunk.updateChunk, bundlePath)
            .then(() => {
              console.log('[Sink] onRequestClosedUpdateChunk (endStream) executed successfully');
            })
            .catch((err: unknown) => {
              console.log('[Sink] ERROR running onRequestClosedUpdateChunk:', err);
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
