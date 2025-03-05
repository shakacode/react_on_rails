"use client";

import * as React from 'react';
import * as ReactDOMClient from 'react-dom/client';
import { createFromReadableStream } from '@shakacode-tools/react-on-rails-rsc/client';
import { fetch } from './utils';
import transformRSCStreamAndReplayConsoleLogs from './transformRSCStreamAndReplayConsoleLogs';
import { RailsContext, RenderFunction } from './types';

const { use } = React;

if (typeof use !== 'function') {
  throw new Error('React.use is not defined. Please ensure you are using React 19 to use server components.');
}

export type RSCClientRootProps = {
  componentName: string;
  rscPayloadGenerationUrlPath: string;
  componentProps?: unknown;
}

const createFromFetch = async (fetchPromise: Promise<Response>) => {
  const response = await fetchPromise;
  const stream = response.body;
  if (!stream) {
    throw new Error('No stream found in response');
  }
  const transformedStream = transformRSCStreamAndReplayConsoleLogs(stream);
  return createFromReadableStream<React.ReactNode>(transformedStream);
}

const fetchRSC = ({ componentName, rscPayloadGenerationUrlPath, componentProps }: RSCClientRootProps) => {
  const propsString = JSON.stringify(componentProps);
  const strippedUrlPath = rscPayloadGenerationUrlPath.replace(/^\/|\/$/g, '');
  return createFromFetch(fetch(`/${strippedUrlPath}/${componentName}?props=${propsString}`));
}

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
 * @requires @shakacode-tools/react-on-rails-rsc
 */
const RSCClientRoot: RenderFunction = async ({
  componentName,
  rscPayloadGenerationUrlPath,
  componentProps,
}: RSCClientRootProps, _railsContext?: RailsContext, domNodeId?: string) => {
  const root = await fetchRSC({ componentName, rscPayloadGenerationUrlPath, componentProps })
  if (!domNodeId) {
    throw new Error('RSCClientRoot: No domNodeId provided');
  }
  const domNode = document.getElementById(domNodeId);
  if (!domNode) {
    throw new Error(`RSCClientRoot: No DOM node found for id: ${domNodeId}`);
  }
  if (domNode.innerHTML) {
    ReactDOMClient.hydrateRoot(domNode, root);
  } else {
    ReactDOMClient.createRoot(domNode).render(root);
  }
  // Added only to satisfy the return type of RenderFunction
  // However, the returned value of renderFunction is not used in ReactOnRails
  // TODO: fix this behavior
  return '';
}

export default RSCClientRoot;
