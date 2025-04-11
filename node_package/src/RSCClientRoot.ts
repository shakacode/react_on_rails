'use client';

import * as React from 'react';
import * as ReactDOMClient from 'react-dom/client';
import { createFromReadableStream } from 'react-on-rails-rsc/client';
import { fetch } from './utils';
import transformRSCStreamAndReplayConsoleLogs from './transformRSCStreamAndReplayConsoleLogs';
import { RailsContext, RenderFunction, RSCPayloadChunk } from './types';
import { ensureReactUseAvailable } from './reactApis';

ensureReactUseAvailable();

declare global {
  interface Window {
    REACT_ON_RAILS_RSC_PAYLOAD?: RSCPayloadChunk[];
  }
}

export type RSCClientRootProps = {
  componentName: string;
  rscPayloadGenerationUrlPath: string;
  componentProps?: unknown;
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

const fetchRSC = ({ componentName, rscPayloadGenerationUrlPath, componentProps }: RSCClientRootProps) => {
  const propsString = JSON.stringify(componentProps);
  const strippedUrlPath = rscPayloadGenerationUrlPath.replace(/^\/|\/$/g, '');
  return createFromFetch(fetch(`/${strippedUrlPath}/${componentName}?props=${propsString}`));
};

const createRSCStreamFromPage = () => {
  let streamController: ReadableStreamController<RSCPayloadChunk> | undefined;
  const stream = new ReadableStream<RSCPayloadChunk>({
    start(controller) {
      if (typeof window === 'undefined') {
        return;
      }
      const handleChunk = (chunk: RSCPayloadChunk) => {
        controller.enqueue(chunk);
      };

      // The RSC payload transfer mechanism works in two possible scenarios:
      // 1. RSCClientRoot executes first:
      //    - Initializes REACT_ON_RAILS_RSC_PAYLOAD as an empty array
      //    - Overrides the push function to handle incoming chunks
      //    - When server scripts run later, they use the overridden push function
      // 2. Server scripts execute first:
      //    - Initialize REACT_ON_RAILS_RSC_PAYLOAD as an empty array
      //    - Buffer RSC payload chunks in the array
      //    - When RSCClientRoot runs, it reads buffered chunks and overrides push
      //
      // Key points:
      // - The array is never reassigned, ensuring data consistency
      // - The push function override ensures all chunks are properly handled
      // - Execution order is irrelevant - both scenarios work correctly
      if (!window.REACT_ON_RAILS_RSC_PAYLOAD) {
        window.REACT_ON_RAILS_RSC_PAYLOAD = [];
      }
      window.REACT_ON_RAILS_RSC_PAYLOAD.forEach(handleChunk);
      window.REACT_ON_RAILS_RSC_PAYLOAD.push = (...chunks) => {
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

const createFromRSCStream = () => {
  const stream = createRSCStreamFromPage();
  const transformedStream = transformRSCStreamAndReplayConsoleLogs(stream);
  return createFromReadableStream<React.ReactNode>(transformedStream);
};

/**
 * RSCClientRoot is a React component that handles client-side rendering of React Server Components (RSC).
 * It manages the fetching, caching, and rendering of RSC payloads from the server.
 *
 * This component:
 * 1. Fetches RSC payloads from the server using the provided URL path
 * 2. Caches the responses to prevent duplicate requests
 * 3. Transforms the response stream to replay server-side console logs
 * 4. Uses React.use() to handle the async data fetching
 *
 * @requires React 19+
 * @requires react-on-rails-rsc
 */
const RSCClientRoot: RenderFunction = async (
  { componentName, rscPayloadGenerationUrlPath, componentProps }: RSCClientRootProps,
  _railsContext?: RailsContext,
  domNodeId?: string,
) => {
  if (!domNodeId) {
    throw new Error('RSCClientRoot: No domNodeId provided');
  }
  const domNode = document.getElementById(domNodeId);
  if (!domNode) {
    throw new Error(`RSCClientRoot: No DOM node found for id: ${domNodeId}`);
  }
  if (domNode.innerHTML) {
    const root = await createFromRSCStream();
    ReactDOMClient.hydrateRoot(domNode, root);
  } else {
    const root = await fetchRSC({ componentName, rscPayloadGenerationUrlPath, componentProps });
    ReactDOMClient.createRoot(domNode).render(root);
  }
  // Added only to satisfy the return type of RenderFunction
  // However, the returned value of renderFunction is not used in ReactOnRails
  // TODO: fix this behavior
  return '';
};

export default RSCClientRoot;
