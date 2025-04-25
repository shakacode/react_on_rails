import { PassThrough } from 'stream';
import { RailsContext } from './types';

declare global {
  function generateRSCPayload(
    componentName: string,
    props: unknown,
    railsContext: RailsContext,
  ): Promise<NodeJS.ReadableStream>;
}

export type RSCPayloadStreamInfo = {
  stream: NodeJS.ReadableStream;
  props: unknown;
  componentName: string;
};

export type RSCPayloadCallback = (streamInfo: RSCPayloadStreamInfo) => void;

const mapRailsContextToRSCPayloadStreams = new Map<RailsContext, RSCPayloadStreamInfo[]>();

const rscPayloadCallbacks = new Map<RailsContext, Array<RSCPayloadCallback>>();

export const onRSCPayloadGenerated = (railsContext: RailsContext, callback: RSCPayloadCallback) => {
  const callbacks = rscPayloadCallbacks.get(railsContext) || [];
  callbacks.push(callback);
  rscPayloadCallbacks.set(railsContext, callbacks);

  // Call callback for any existing streams for this context
  const existingStreams = mapRailsContextToRSCPayloadStreams.get(railsContext) || [];
  existingStreams.forEach((streamInfo) => callback(streamInfo));
};

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

  // Notify callbacks about the new stream
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
