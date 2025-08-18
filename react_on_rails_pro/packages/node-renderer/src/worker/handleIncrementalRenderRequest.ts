import { Readable } from 'stream';
import type { ResponseResult } from '../shared/utils';

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
 * Starts handling an incremental render request. This function is intended to:
 * - Initialize any resources needed to process the render
 * - Return both a stream that will be sent to the client and a sink for incoming chunks
 *
 * NOTE: This is intentionally left unimplemented. Tests should mock this.
 */
export function handleIncrementalRenderRequest(initial: IncrementalRenderInitialRequest): Promise<IncrementalRenderResult> {
  // Empty placeholder implementation. Real logic will be added later.
  return Promise.resolve({
    response: {
      status: 200,
      headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
      stream: new Readable({
        read() {
          // No-op for now
        },
      }),
    } as ResponseResult,
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
  });
}

export type { ResponseResult };
