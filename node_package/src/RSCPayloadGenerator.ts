import { PassThrough } from 'stream';
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

const mapRailsContextToRSCPayloadStreams = new Map<string, RSCPayloadStreamInfo[]>();

const rscPayloadCallbacks = new Map<string, Array<RSCPayloadCallback>>();

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
  const callbacks = rscPayloadCallbacks.get(renderRequestId) || [];
  callbacks.push(callback);
  rscPayloadCallbacks.set(renderRequestId, callbacks);

  // Call callback for any existing streams for this context
  const existingStreams = mapRailsContextToRSCPayloadStreams.get(renderRequestId) || [];
  existingStreams.forEach((streamInfo) => callback(streamInfo));
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
  const streams = mapRailsContextToRSCPayloadStreams.get(renderRequestId) ?? [];
  const stream1 = new PassThrough();
  stream.pipe(stream1);
  const stream2 = new PassThrough();
  stream.pipe(stream2);

  const streamInfo: RSCPayloadStreamInfo = {
    componentName,
    props,
    stream: stream2,
  };
  streams.push(streamInfo);
  mapRailsContextToRSCPayloadStreams.set(renderRequestId, streams);

  // Notify callbacks about the new stream in a sync manner to maintain proper hydration timing
  // as described in the comment above onRSCPayloadGenerated
  const callbacks = rscPayloadCallbacks.get(renderRequestId) || [];
  callbacks.forEach((callback) => callback(streamInfo));

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
  return mapRailsContextToRSCPayloadStreams.get(renderRequestId) ?? [];
};

export const clearRSCPayloadStreams = (railsContext: RailsContextWithServerComponentCapabilities) => {
  const { renderRequestId } = railsContext.componentSpecificMetadata;
  mapRailsContextToRSCPayloadStreams.delete(renderRequestId);
  rscPayloadCallbacks.delete(renderRequestId);
};
