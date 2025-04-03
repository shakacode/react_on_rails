import { renderToPipeableStream } from 'react-on-rails-rsc/server.node';
import { PassThrough, Readable } from 'stream';
import type { ReactElement } from 'react';

import { RSCRenderParams, StreamRenderState } from './types/index.ts';
import ReactOnRails from './ReactOnRails.full.ts';
import buildConsoleReplay from './buildConsoleReplay.ts';
import handleError from './handleError.ts';
import { convertToError, createResultObject } from './serverRenderUtils.ts';

import {
  streamServerRenderedComponent,
  transformRenderStreamChunksToResultObject,
} from './streamServerRenderedReactComponent.ts';
import loadReactClientManifest from './loadReactClientManifest.ts';

const stringToStream = (str: string) => {
  const stream = new PassThrough();
  stream.push(str);
  stream.push(null);
  return stream;
};

const streamRenderRSCComponent = (reactElement: ReactElement, options: RSCRenderParams): Readable => {
  const { throwJsErrors, reactClientManifestFileName } = options;
  const renderState: StreamRenderState = {
    result: null,
    hasErrors: false,
    isShellReady: true,
  };

  const { pipeToTransform, readableStream, emitError } =
    transformRenderStreamChunksToResultObject(renderState);
  loadReactClientManifest(reactClientManifestFileName)
    .then((reactClientManifest) => {
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

export * from './types/index.ts';
export default ReactOnRails;
