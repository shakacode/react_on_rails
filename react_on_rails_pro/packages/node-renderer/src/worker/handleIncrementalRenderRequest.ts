import type { FastifyReply } from './types';
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

/**
 * Starts handling an incremental render request. This function is intended to:
 * - Initialize any resources needed to process the render
 * - Potentially start sending a streaming response via FastifyReply
 * - Return a sink that the HTTP endpoint will use to push additional NDJSON
 *   chunks as they arrive
 *
 * NOTE: This is intentionally left unimplemented. Tests should mock this.
 */
export function handleIncrementalRenderRequest(_params: {
  initial: IncrementalRenderInitialRequest;
  reply: FastifyReply;
}): Promise<IncrementalRenderSink> {
  // Empty placeholder implementation. Real logic will be added later.
  return Promise.resolve({
    add: () => {
      /* no-op */
    },
    end: () => {
      /* no-op */
    },
    abort: () => {
      /* no-op */
    },
  });
}

export type { ResponseResult };
