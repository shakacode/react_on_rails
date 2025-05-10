import { PassThrough } from 'stream';
import { RailsContext, RSCPayloadStreamInfo, RSCPayloadCallback } from './types/index.ts';

declare global {
  function generateRSCPayload(
    componentName: string,
    props: unknown,
    railsContext: RailsContext,
  ): Promise<NodeJS.ReadableStream>;
}

const mapRailsContextToRSCPayloadStreams = new Map<RailsContext, RSCPayloadStreamInfo[]>();

const rscPayloadCallbacks = new Map<RailsContext, Array<RSCPayloadCallback>>();

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
export const onRSCPayloadGenerated = (railsContext: RailsContext, callback: RSCPayloadCallback) => {
  const callbacks = rscPayloadCallbacks.get(railsContext) || [];
  callbacks.push(callback);
  rscPayloadCallbacks.set(railsContext, callbacks);

  // Call callback for any existing streams for this context
  const existingStreams = mapRailsContextToRSCPayloadStreams.get(railsContext) || [];
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
  railsContext: RailsContext,
): Promise<NodeJS.ReadableStream> => {
  if (typeof generateRSCPayload !== 'function') {
    throw new Error(
      'generateRSCPayload is not defined. Please ensure that you are using at least version 4.0.0 of ' +
        'React on Rails Pro and the Node renderer, and that ReactOnRailsPro.configuration.enable_rsc_support ' +
        'is set to true.',
    );
  }

  const stream = await generateRSCPayload(componentName, props, railsContext);
  const streams = mapRailsContextToRSCPayloadStreams.get(railsContext) ?? [];
  const stream1 = new PassThrough();
  stream.pipe(stream1);
  const stream2 = new PassThrough();
  stream1.pipe(stream2);

  const streamInfo: RSCPayloadStreamInfo = {
    componentName,
    props,
    stream: stream2,
  };
  streams.push(streamInfo);
  mapRailsContextToRSCPayloadStreams.set(railsContext, streams);

  // Notify callbacks about the new stream in a sync manner to maintain proper hydration timing
  // as described in the comment above onRSCPayloadGenerated
  const callbacks = rscPayloadCallbacks.get(railsContext) || [];
  callbacks.forEach((callback) => callback(streamInfo));

  return stream1;
};

export const getRSCPayloadStreams = (
  railsContext: RailsContext,
): {
  componentName: string;
  props: unknown;
  stream: NodeJS.ReadableStream;
}[] => mapRailsContextToRSCPayloadStreams.get(railsContext) ?? [];

export const clearRSCPayloadStreams = (railsContext: RailsContext) => {
  mapRailsContextToRSCPayloadStreams.delete(railsContext);
  rscPayloadCallbacks.delete(railsContext);
};
