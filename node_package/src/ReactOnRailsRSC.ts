import { renderToPipeableStream } from 'react-on-rails-rsc/server.node';
import { PassThrough, Readable } from 'stream';

import { RSCRenderParams, StreamRenderState, StreamableComponentResult } from './types';
import ReactOnRails from './ReactOnRails.full';
import buildConsoleReplay from './buildConsoleReplay';
import handleError from './handleError';
import { convertToError, createResultObject } from './serverRenderUtils';

import {
  streamServerRenderedComponent,
  transformRenderStreamChunksToResultObject,
} from './streamServerRenderedReactComponent';
import loadJsonFile from './loadJsonFile';

const stringToStream = (str: string) => {
  const stream = new PassThrough();
  stream.push(str);
  stream.push(null);
  return stream;
};

const streamRenderRSCComponent = (
  reactRenderingResult: StreamableComponentResult,
  options: RSCRenderParams,
): Readable => {
  const { throwJsErrors, reactClientManifestFileName } = options;
  const renderState: StreamRenderState = {
    result: null,
    hasErrors: false,
    isShellReady: true,
  };

  const { pipeToTransform, readableStream, emitError } =
    transformRenderStreamChunksToResultObject(renderState);
  Promise.all([loadJsonFile(reactClientManifestFileName), reactRenderingResult])
    .then(([reactClientManifest, reactElement]) => {
      const rscStream = renderToPipeableStream(reactElement, reactClientManifest, {
        onError: (err) => {
          const error = convertToError(err);
          console.error('Error in RSC stream', error);
          if (throwJsErrors) {
            emitError(error);
          }
          renderState.hasErrors = true;
          renderState.error = error;
        },
      });
      pipeToTransform(rscStream);
    })
    .catch((e: unknown) => {
      const error = convertToError(e);
      renderState.hasErrors = true;
      renderState.error = error;
      const htmlResult = handleError({ e: error, name: options.name, serverSide: true });
      const jsonResult = JSON.stringify(createResultObject(htmlResult, buildConsoleReplay(), renderState));
      return stringToStream(jsonResult);
    });
  return readableStream;
};

ReactOnRails.serverRenderRSCReactComponent = (options: RSCRenderParams) => {
  try {
    return streamServerRenderedComponent(options, streamRenderRSCComponent);
  } finally {
    console.history = [];
  }
};

ReactOnRails.isRSCBundle = true;

ReactOnRails.registerServerComponentReferences = () => {
  throw new Error('registerServerComponentReferences is not supported in the RSC bundle. Server components themselves should be registered not referenced.');
}

export * from './types';
export default ReactOnRails;
