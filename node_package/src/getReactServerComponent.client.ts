import * as React from 'react';
import { createFromReadableStream } from 'react-on-rails-rsc/client.browser';
import { createRSCPayloadKey, fetch, wrapInNewPromise } from './utils.ts';
import transformRSCStreamAndReplayConsoleLogs from './transformRSCStreamAndReplayConsoleLogs.ts';
import { assertRailsContextWithComponentSpecificMetadata, RailsContext } from './types/index.ts';

declare global {
  interface Window {
    REACT_ON_RAILS_RSC_PAYLOADS?: Record<string, string[]>;
  }
}

type ClientGetReactServerComponentProps = {
  componentName: string;
  componentProps: unknown;
  railsContext: RailsContext;
  enforceRefetch?: boolean;
};

const createFromFetch = async (fetchPromise: Promise<Response>) => {
  const response = await fetchPromise;
  const stream = response.body;
  if (!stream) {
    throw new Error('No stream found in response');
  }
  const transformedStream = transformRSCStreamAndReplayConsoleLogs(stream);
  const renderPromise = createFromReadableStream<React.ReactNode>(transformedStream);
  return wrapInNewPromise(renderPromise);
};

/**
 * Fetches an RSC payload via HTTP request.
 *
 * This function:
 * 1. Serializes the component props
 * 2. Makes an HTTP request to the RSC payload generation endpoint
 * 3. Processes the response stream into React elements
 *
 * This is used for client-side navigation or when rendering components
 * that weren't part of the initial server render.
 *
 * @param props - Object containing component name, props, and railsContext
 * @returns A Promise resolving to the rendered React element
 */
const fetchRSC = ({ componentName, componentProps, railsContext }: ClientGetReactServerComponentProps) => {
  const propsString = JSON.stringify(componentProps);
  const { rscPayloadGenerationUrlPath } = railsContext;
  const strippedUrlPath = rscPayloadGenerationUrlPath?.replace(/^\/|\/$/g, '');
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
      // eslint-disable-next-line no-param-reassign
      payloads.push = (...chunks) => {
        chunks.forEach(handleChunk);
        return chunks.length;
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

/**
 * Creates React elements from preloaded RSC payloads in the page.
 *
 * This function:
 * 1. Creates a ReadableStream from the array of payload chunks
 * 2. Transforms the stream to handle console logs and other processing
 * 3. Uses React's createFromReadableStream to process the payload
 *
 * This is used during hydration to avoid making HTTP requests when
 * the payload is already embedded in the page.
 *
 * @param payloads - Array of RSC payload chunks from the global array
 * @returns A Promise resolving to the rendered React element
 */
const createFromPreloadedPayloads = (payloads: string[]) => {
  const stream = createRSCStreamFromArray(payloads);
  const transformedStream = transformRSCStreamAndReplayConsoleLogs(stream);
  const renderPromise = createFromReadableStream<React.ReactNode>(transformedStream);
  return wrapInNewPromise(renderPromise);
};

/**
 * Fetches and renders a server component on the client side.
 *
 * This function:
 * 1. Checks for embedded RSC payloads in window.REACT_ON_RAILS_RSC_PAYLOADS
 * 2. If found, uses the embedded payload to avoid an HTTP request
 * 3. If not found (during client navigation or dynamic rendering), fetches via HTTP
 * 4. Processes the RSC payload into React elements
 *
 * The embedded payload approach ensures optimal performance during initial page load,
 * while the HTTP fallback enables dynamic rendering after navigation.
 *
 * @param componentName - Name of the server component to render
 * @param componentProps - Props to pass to the server component
 * @param railsContext - Context for the current request
 * @param enforceRefetch - Whether to enforce a refetch of the component
 * @returns A Promise resolving to the rendered React element
 *
 * @important This is an internal function. End users should not use this directly.
 * Instead, use the useRSC hook which provides getComponent and refetchComponent functions
 * for fetching or retrieving cached server components. For rendering server components,
 * consider using RSCRoute component which handles the rendering logic automatically.
 */
const getReactServerComponent = ({
  componentName,
  componentProps,
  railsContext,
  enforceRefetch = false,
}: ClientGetReactServerComponentProps) => {
  assertRailsContextWithComponentSpecificMetadata(railsContext);
  const componentKey = createRSCPayloadKey(componentName, componentProps, railsContext);
  const payloads = window.REACT_ON_RAILS_RSC_PAYLOADS?.[componentKey];
  if (!enforceRefetch && payloads) {
    return createFromPreloadedPayloads(payloads);
  }
  return fetchRSC({ componentName, componentProps, railsContext });
};

export default getReactServerComponent;
