import * as React from 'react';
import RSDWClient from 'react-server-dom-webpack/client';
import transformRSCStreamAndReplayConsoleLogs from './transformRSCStreamAndReplayConsoleLogs';
import { rscStream } from './readRSCOnClient';

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
  rscRenderingUrlPath: string;
}

const fetchRSC = ({ componentName }: RSCClientRootProps) => {
  if (!renderCache[componentName]) {
    const transformedStream = transformRSCStreamAndReplayConsoleLogs(rscStream);
    renderCache[componentName] = RSDWClient.createFromReadableStream(transformedStream);
  }
  return renderCache[componentName];
}

const RSCClientRoot = ({
  componentName,
  rscRenderingUrlPath,
}: RSCClientRootProps) => use(fetchRSC({ componentName, rscRenderingUrlPath }));

export default RSCClientRoot;
