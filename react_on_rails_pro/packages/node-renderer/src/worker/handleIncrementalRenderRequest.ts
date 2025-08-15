import { Readable } from 'stream';
import { EventEmitter } from 'events';
import type { ResponseResult } from '../shared/utils';
import { validateAndGetBundlePaths, buildVMsForBundles, executeRenderInVM } from './sharedRenderUtils';

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
  dependencyBundleTimestamps?: Array<string | number>;
};

export type IncrementalRenderResult = {
  response: ResponseResult;
  sink: IncrementalRenderSink;
};

/**
 * Starts handling an incremental render request. This function:
 * - Creates an EventEmitter for handling updates
 * - Builds the VM if needed
 * - Executes the initial render request
 * - Returns both a stream that will be sent to the client and a sink for incoming chunks
 */
export async function handleIncrementalRenderRequest(
  initial: IncrementalRenderInitialRequest,
): Promise<IncrementalRenderResult> {
  const { renderingRequest, bundleTimestamp, dependencyBundleTimestamps } = initial;

  // Create event emitter for this specific request
  const updateEmitter = new EventEmitter();

  // Validate bundles and get paths
  const validationResult = await validateAndGetBundlePaths(bundleTimestamp, dependencyBundleTimestamps);
  if (!validationResult.success || !validationResult.bundleFilePath) {
    return {
      response: validationResult.error || {
        status: 500,
        headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
        data: 'Bundle validation failed',
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

  // Build VMs
  const vmBuildResult = await buildVMsForBundles(
    validationResult.bundleFilePath,
    validationResult.dependencyBundleFilePaths || [],
  );
  if (!vmBuildResult.success) {
    return {
      response: vmBuildResult.error || {
        status: 500,
        headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
        data: 'VM building failed',
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

  // Create the response stream
  const responseStream = new Readable({
    read() {
      // No-op - data will be pushed via events
    },
  });

  // Set up event listeners for the response stream
  updateEmitter.on('update', (data: unknown) => {
    // Push update data to the response stream
    responseStream.push(`${JSON.stringify(data)}\n`);
  });

  updateEmitter.on('end', () => {
    // End the response stream
    responseStream.push(null);
  });

  updateEmitter.on('error', (error: unknown) => {
    // Handle error and end stream
    const errorMessage = error instanceof Error ? error.message : String(error);
    responseStream.push(`{"error":"${errorMessage}"}\n`);
    responseStream.push(null);
  });

  // Execute the initial render request with the update emitter
  const executionResult = await executeRenderInVM(
    renderingRequest,
    validationResult.bundleFilePath,
    updateEmitter,
  );

  // Handle the render result
  if (executionResult.success && executionResult.result) {
    // Initial render completed successfully
    if (executionResult.result.data) {
      const dataString =
        typeof executionResult.result.data === 'string'
          ? executionResult.result.data
          : JSON.stringify(executionResult.result.data);
      responseStream.push(`${dataString}\n`);
    }
  } else {
    // Render failed
    const errorMessage =
      typeof executionResult.error?.data === 'string' ? executionResult.error.data : 'Unknown render error';
    responseStream.push(`{"error":"${errorMessage}"}\n`);
    responseStream.push(null);
    return {
      response: executionResult.error || {
        status: 500,
        headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
        data: 'Render execution failed',
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

  return {
    response: {
      status: 200,
      headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
      stream: responseStream,
    },
    sink: {
      add: (chunk: unknown) => {
        // Emit event when chunk arrives
        updateEmitter.emit('update', chunk);
      },
      end: () => {
        updateEmitter.emit('end');
      },
      abort: (error: unknown) => {
        updateEmitter.emit('error', error);
      },
    },
  };
}

export type { ResponseResult };
