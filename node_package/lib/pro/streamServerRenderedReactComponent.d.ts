import { Readable } from 'stream';
import {
  RenderParams,
  StreamRenderState,
  StreamableComponentResult,
  PipeableOrReadableStream,
} from '../types/index.ts';
import PostSSRHookTracker from './PostSSRHookTracker.ts';
import RSCRequestTracker from './RSCRequestTracker.ts';

export declare const transformRenderStreamChunksToResultObject: (renderState: StreamRenderState) => {
  readableStream: Readable;
  pipeToTransform: (pipeableStream: PipeableOrReadableStream) => void;
  writeChunk: (chunk: string) => boolean;
  emitError: (error: unknown) => void;
  endStream: () => void;
};
export type StreamingTrackers = {
  postSSRHookTracker: PostSSRHookTracker;
  rscRequestTracker: RSCRequestTracker;
};
type StreamRenderer<T, P extends RenderParams> = (
  reactElement: StreamableComponentResult,
  options: P,
  streamingTrackers: StreamingTrackers,
) => T;
/**
 * This module implements request-scoped tracking for React Server Components (RSC)
 * and post-SSR hooks using local tracker instances per request.
 *
 * DESIGN PRINCIPLES:
 * - Each request gets its own PostSSRHookTracker and RSCRequestTracker instances
 * - State is automatically garbage collected when request completes
 * - No shared state between concurrent requests
 * - Simple, predictable cleanup lifecycle
 *
 * TRACKER RESPONSIBILITIES:
 * - PostSSRHookTracker: Manages hooks that run after SSR completes
 * - RSCRequestTracker: Handles RSC payload generation and stream tracking
 * - Both inject their capabilities into the Rails context for component access
 */
export declare const streamServerRenderedComponent: <T, P extends RenderParams>(
  options: P,
  renderStrategy: StreamRenderer<T, P>,
) => T;
declare const streamServerRenderedReactComponent: (options: RenderParams) => Readable;
export default streamServerRenderedReactComponent;
