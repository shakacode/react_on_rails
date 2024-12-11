import * as React from 'react';
import RSDWClient from 'react-server-dom-webpack/client';
import transformRSCStreamAndReplayConsoleLogs from './transformRSCStreamAndReplayConsoleLogs';

if (!('use' in React)) {
  throw new Error('React.use is not defined. Please ensure you are using React 18.3.0-canary-670811593-20240322 or later to use server components.');
}

// It's not the exact type, but it's close enough for now
type Use = <T>(promise: Promise<T>) => T;
const { use } = React as { use: Use };

const renderCache: Record<string, Promise<unknown>> = {};

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
    renderCache[componentName] = createFromFetch(fetch(`/rsc/${componentName}`));
  }
  return renderCache[componentName];
}

const RSCClientRoot = ({ componentName }: { componentName: string }) => use(fetchRSC({ componentName }));

export default RSCClientRoot;
