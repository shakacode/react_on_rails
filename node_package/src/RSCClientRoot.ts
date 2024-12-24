import * as React from 'react';
import RSDWClient from 'react-server-dom-webpack/client';
import transformRSCStreamAndReplayConsoleLogs from './transformRSCStreamAndReplayConsoleLogs';

if (!('use' in React)) {
  throw new Error('React.use is not defined. Please ensure you are using React 18 with experimental features enabled or React 19+ to use server components.');
}

const { use } = React;

const renderCache: Record<string, Promise<React.ReactNode>> = {};

const createFromFetch = async (fetchPromise: Promise<Response>) => {
  const response = await fetchPromise;
  const stream = response.body;
  if (!stream) {
    throw new Error('No stream found in response');
  }
  const transformedStream = transformRSCStreamAndReplayConsoleLogs(stream);
  return RSDWClient.createFromReadableStream(transformedStream);
}

const fetchRSC = ({ componentName }: { componentName: string }) => {
  if (!renderCache[componentName]) {
    renderCache[componentName] = createFromFetch(fetch(`/rsc/${componentName}`)) as Promise<React.ReactNode>;
  }
  return renderCache[componentName];
}

const RSCClientRoot = ({ componentName }: { componentName: string }) => use(fetchRSC({ componentName }));

export default RSCClientRoot;
