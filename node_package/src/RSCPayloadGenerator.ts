import { PassThrough } from 'stream';
import { RailsContext } from './types';

declare global {
  function generateRSCPayload(
    componentName: string,
    props: unknown,
    railsContext: RailsContext,
  ): Promise<NodeJS.ReadableStream>;
}

const mapRailsContextToRSCPayloadStreams = new Map<
  RailsContext,
  {
    componentName: string;
    props: unknown;
    stream: NodeJS.ReadableStream;
  }[]
>();

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

  streams.push({
    componentName,
    props,
    stream: stream2,
  });
  mapRailsContextToRSCPayloadStreams.set(railsContext, streams);
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
};
