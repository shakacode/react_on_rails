"use client";

import * as React from 'react';
import * as RSDWClient from 'react-server-dom-webpack/client';
import { fetch } from './utils';
import transformRSCStreamAndReplayConsoleLogs from './transformRSCStreamAndReplayConsoleLogs';

if (!('use' in React && typeof React.use === 'function')) {
  throw new Error('React.use is not defined. Please ensure you are using React 18 with experimental features enabled or React 19+ to use server components.');
}

const { use } = React;

let renderCache: Record<string, Promise<React.ReactNode>> = {};
export const resetRenderCache = () => {
  renderCache = {};
}

export type RSCClientRootProps = {
  componentName: string;
  rscPayloadGenerationUrlPath: string;
}

const createFromFetch = async (fetchPromise: Promise<Response>) => {
  const response = await fetchPromise;
  const stream = response.body;
  if (!stream) {
    throw new Error('No stream found in response');
  }
  const transformedStream = transformRSCStreamAndReplayConsoleLogs(stream);
  return RSDWClient.createFromReadableStream(transformedStream);
}

const fetchRSC = ({ componentName, rscPayloadGenerationUrlPath }: RSCClientRootProps) => {
  if (!renderCache[componentName]) {
    const strippedUrlPath = rscPayloadGenerationUrlPath.replace(/^\/|\/$/g, '');
    renderCache[componentName] = createFromFetch(fetch(`/${strippedUrlPath}/${componentName}`)) as Promise<React.ReactNode>;
  }
  return renderCache[componentName];
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
 * @requires React 18+ with experimental features or React 19+
 * @requires react-server-dom-webpack/client
 */
const RSCClientRoot = ({
  componentName,
  rscPayloadGenerationUrlPath,
}: RSCClientRootProps) => use(fetchRSC({ componentName, rscPayloadGenerationUrlPath }));

export default RSCClientRoot;
