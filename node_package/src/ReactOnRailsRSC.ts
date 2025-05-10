import { renderToPipeableStream } from 'react-on-rails-rsc/server.node';
import { PassThrough, Readable } from 'stream';

import { RSCRenderParams, StreamRenderState, StreamableComponentResult } from './types/index.ts';
import ReactOnRails from './ReactOnRails.full.ts';
import buildConsoleReplay from './buildConsoleReplay.ts';
import handleError from './handleError.ts';
import { convertToError, createResultObject } from './serverRenderUtils.ts';
import { notifySSREnd, addPostSSRHook } from './postSSRHooks.ts';

import {
  streamServerRenderedComponent,
  transformRenderStreamChunksToResultObject,
} from './streamServerRenderedReactComponent.ts';
import loadJsonFile from './loadJsonFile.ts';

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
  const { throwJsErrors } = options;
  if (!options.railsContext?.serverSide || !options.railsContext.reactClientManifestFileName) {
    throw new Error('Rails context is not available');
  }

  const { reactClientManifestFileName } = options.railsContext;
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

  readableStream.on('end', () => {
    if (options.railsContext?.componentSpecificMetadata) {
      notifySSREnd(options.railsContext as RailsContextWithComponentSpecificMetadata);
    }
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

ReactOnRails.addPostSSRHook = addPostSSRHook;

ReactOnRails.isRSCBundle = true;

export * from './types/index.ts';
export default ReactOnRails;
