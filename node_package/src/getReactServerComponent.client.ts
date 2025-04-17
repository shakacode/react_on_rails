import * as React from 'react';
import { createFromReadableStream } from 'react-on-rails-rsc/client';
import { fetch } from './utils';
import transformRSCStreamAndReplayConsoleLogs from './transformRSCStreamAndReplayConsoleLogs';
import { RailsContext } from './types';

declare global {
  interface Window {
    REACT_ON_RAILS_RSC_PAYLOADS?: Record<string, string[]>;
  }
}

export type ClientGetReactServerComponentProps = {
  componentName: string;
  componentProps: unknown;
  railsContext: RailsContext;
};

const createFromFetch = async (fetchPromise: Promise<Response>) => {
  const response = await fetchPromise;
  const stream = response.body;
  if (!stream) {
    throw new Error('No stream found in response');
  }
  const transformedStream = transformRSCStreamAndReplayConsoleLogs(stream);
  return createFromReadableStream<React.ReactNode>(transformedStream);
};

const fetchRSC = ({ componentName, componentProps, railsContext }: ClientGetReactServerComponentProps) => {
  const propsString = JSON.stringify(componentProps);
  const { rscPayloadGenerationUrl } = railsContext;
  const strippedUrlPath = rscPayloadGenerationUrl?.replace(/^\/|\/$/g, '');
  return createFromFetch(fetch(`/${strippedUrlPath}/${componentName}?props=${propsString}`));
};

const createRSCStreamFromArray = (payloads: string[]) => {
  let streamController: ReadableStreamController<string> | undefined;
  const stream = new ReadableStream<string>({
    start(controller) {
      if (typeof window === 'undefined') {
        return;
      }
      const handleChunk = (chunk: string) => {
        controller.enqueue(chunk);
      };

      payloads.forEach(handleChunk);
      const originalPush = payloads.push;
      // eslint-disable-next-line no-param-reassign
      payloads.push = (...chunks) => {
        chunks.forEach(handleChunk);
        return originalPush.call(payloads, ...chunks);
      };
      streamController = controller;
    },
  });

  if (typeof document !== 'undefined' && document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      streamController?.close();
    });
  } else {
    streamController?.close();
  }

  return stream;
};

const createFromPreloadedPayloads = (payloads: string[]) => {
  const stream = createRSCStreamFromArray(payloads);
  const transformedStream = transformRSCStreamAndReplayConsoleLogs(stream);
  return createFromReadableStream<React.ReactNode>(transformedStream);
};

export const getReactServerComponent = ({
  componentName,
  componentProps,
  railsContext,
}: ClientGetReactServerComponentProps) => {
  const componentKey = `${componentName}-${JSON.stringify(componentProps)}-${railsContext.componentSpecificMetadata?.renderRequestId}`;
  const payloads = window.REACT_ON_RAILS_RSC_PAYLOADS?.[componentKey];
  if (payloads) {
    return createFromPreloadedPayloads(payloads);
  }
  return fetchRSC({ componentName, componentProps, railsContext });
};

export const getPreloadedReactServerComponents = (railsContext: RailsContext) => {
  return Promise.all(
    Object.entries(window.REACT_ON_RAILS_RSC_PAYLOADS ?? {})
      .filter(([cacheKey]) =>
        cacheKey.includes(railsContext.componentSpecificMetadata?.renderRequestId ?? ''),
      )
      .map(async ([cacheKey, payloads]) => ({
        [cacheKey]: await createFromPreloadedPayloads(payloads),
      })),
  ).then((components) => Object.assign({}, ...components) as Record<string, React.ReactNode>);
};
