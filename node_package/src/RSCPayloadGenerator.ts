import { PassThrough, Readable } from 'stream';
import {
  RailsContextWithServerComponentCapabilities,
  RSCPayloadStreamInfo,
  RSCPayloadCallback,
} from './types/index.ts';

declare global {
  function generateRSCPayload(
    componentName: string,
    props: unknown,
    railsContext: RailsContextWithServerComponentCapabilities,
  ): Promise<NodeJS.ReadableStream>;
}

const rscPayloadStreams = new Map<string, RSCPayloadStreamInfo[]>();
const rscPayloadCallbacks = new Map<string, RSCPayloadCallback[]>();

/**
 * TTL (Time To Live) tracking for RSC payload cleanup.
 * This Map stores timeout IDs for automatic cleanup of RSC payload data.
 * The TTL mechanism serves as a safety net to prevent memory leaks in case
 * the normal cleanup path (via clearRSCPayloadStreams) is not called.
 */
const rscPayloadTTLs = new Map<string, NodeJS.Timeout>();

/**
 * Default TTL duration of 5 minutes (300000 ms).
 * This duration should be long enough to accommodate normal request processing
 * while preventing long-term memory leaks if cleanup is missed.
 */
const DEFAULT_TTL = 300000;

export const clearRSCPayloadStreams = (railsContext: RailsContextWithServerComponentCapabilities) => {
  const { renderRequestId } = railsContext.componentSpecificMetadata;
  // Close any active streams before clearing
  const streams = rscPayloadStreams.get(renderRequestId);
  if (streams) {
    streams.forEach(({ stream }) => {
      if (typeof (stream as Readable).destroy === 'function') {
        (stream as Readable).destroy();
      }
    });
  }
  rscPayloadStreams.delete(renderRequestId);
  rscPayloadCallbacks.delete(renderRequestId);

  // Clear TTL if it exists
  const ttl = rscPayloadTTLs.get(renderRequestId);
  if (ttl) {
    clearTimeout(ttl);
    rscPayloadTTLs.delete(renderRequestId);
  }
};

/**
 * Schedules automatic cleanup of RSC payload data after a TTL period.
 * The TTL mechanism is necessary because:
 * - It prevents memory leaks if clearRSCPayloadStreams is not called (e.g., due to errors)
 * - It ensures cleanup happens even if the request is abandoned or times out
 * - It provides a safety net for edge cases where the normal cleanup path might be missed
 *
 * @param railsContext - The Rails context containing the renderRequestId to schedule cleanup for
 */
function scheduleCleanup(railsContext: RailsContextWithServerComponentCapabilities) {
  const { renderRequestId } = railsContext.componentSpecificMetadata;
  // Clear any existing TTL to prevent multiple cleanup timers
  const existingTTL = rscPayloadTTLs.get(renderRequestId);
  if (existingTTL) {
    clearTimeout(existingTTL);
  }

  // Set new TTL that will trigger cleanup after DEFAULT_TTL milliseconds
  const ttl = setTimeout(() => {
    clearRSCPayloadStreams(railsContext);
  }, DEFAULT_TTL);

  rscPayloadTTLs.set(renderRequestId, ttl);
}

/**
 * Registers a callback to be executed when RSC payloads are generated.
 *
 * This function:
 * 1. Stores the callback function by railsContext
 * 2. Immediately executes the callback for any existing streams
 *
 * This synchronous execution is critical for preventing hydration race conditions.
 * It ensures payload array initialization happens before component HTML appears
 * in the response stream.
 *
 * @param railsContext - Context for the current request
 * @param callback - Function to call when an RSC payload is generated
 */
export const onRSCPayloadGenerated = (
  railsContext: RailsContextWithServerComponentCapabilities,
  callback: RSCPayloadCallback,
) => {
  const { renderRequestId } = railsContext.componentSpecificMetadata;
  const callbacks = rscPayloadCallbacks.get(renderRequestId);
  if (callbacks) {
    callbacks.push(callback);
  } else {
    rscPayloadCallbacks.set(renderRequestId, [callback]);
  }

  // This ensures we have a safety net even if the normal cleanup path fails
  scheduleCleanup(railsContext);

  // Call callback for any existing streams for this context
  const existingStreams = rscPayloadStreams.get(renderRequestId);
  if (existingStreams) {
    existingStreams.forEach((streamInfo) => callback(streamInfo));
  }
};

/**
 * Generates and tracks RSC payloads for server components.
 *
 * getRSCPayloadStream:
 * 1. Calls the global generateRSCPayload function
 * 2. Tracks streams by railsContext for later injection
 * 3. Notifies callbacks immediately to enable early payload embedding
 *
 * The immediate callback notification is critical for preventing hydration race conditions,
 * as it ensures the payload array is initialized in the HTML stream before component rendering.
 *
 * @param componentName - Name of the server component
 * @param props - Props for the server component
 * @param railsContext - Context for the current request
 * @returns A stream of the RSC payload
 */
export const getRSCPayloadStream = async (
  componentName: string,
  props: unknown,
  railsContext: RailsContextWithServerComponentCapabilities,
): Promise<NodeJS.ReadableStream> => {
  if (typeof generateRSCPayload !== 'function') {
    throw new Error(
      'generateRSCPayload is not defined. Please ensure that you are using at least version 4.0.0 of ' +
        'React on Rails Pro and the Node renderer, and that ReactOnRailsPro.configuration.enable_rsc_support ' +
        'is set to true.',
    );
  }

  const { renderRequestId } = railsContext.componentSpecificMetadata;
  const stream = await generateRSCPayload(componentName, props, railsContext);
  // Tee stream to allow for multiple consumers:
  //   1. stream1 - Used by React's runtime to perform server-side rendering
  //   2. stream2 - Used by react-on-rails to embed the RSC payloads
  //      into the HTML stream for client-side hydration
  const stream1 = new PassThrough();
  stream.pipe(stream1);
  const stream2 = new PassThrough();
  stream.pipe(stream2);

  const streamInfo: RSCPayloadStreamInfo = {
    componentName,
    props,
    stream: stream2,
  };
  const streams = rscPayloadStreams.get(renderRequestId);
  if (streams) {
    streams.push(streamInfo);
  } else {
    rscPayloadStreams.set(renderRequestId, [streamInfo]);
  }

  // Notify callbacks about the new stream in a sync manner to maintain proper hydration timing
  // as described in the comment above onRSCPayloadGenerated
  const callbacks = rscPayloadCallbacks.get(renderRequestId);
  if (callbacks) {
    callbacks.forEach((callback) => callback(streamInfo));
  }

  return stream1;
};

export const getRSCPayloadStreams = (
  railsContext: RailsContextWithServerComponentCapabilities,
): {
  componentName: string;
  props: unknown;
  stream: NodeJS.ReadableStream;
}[] => {
  const { renderRequestId } = railsContext.componentSpecificMetadata;
  return rscPayloadStreams.get(renderRequestId) ?? [];
};
