/* Copyright (c) 2015–2025 ShakaCode, LLC
   SPDX-License-Identifier: MIT */
import { BundleManifest } from 'react-on-rails-rsc';
import { buildServerRenderer } from 'react-on-rails-rsc/server.node';
import { Readable } from 'stream';

import {
  RSCRenderParams,
  assertRailsContextWithServerStreamingCapabilities,
  StreamRenderState,
  StreamableComponentResult,
} from './types/index.ts';
import ReactOnRails from './ReactOnRails.full.ts';
import handleError from './handleError.ts';
import { convertToError } from './serverRenderUtils.ts';

import {
  streamServerRenderedComponent,
  StreamingTrackers,
  transformRenderStreamChunksToResultObject,
} from './streamServerRenderedReactComponent.ts';
import loadJsonFile from './loadJsonFile.ts';

let serverRendererPromise: Promise<ReturnType<typeof buildServerRenderer>> | undefined;

const streamRenderRSCComponent = (
  reactRenderingResult: StreamableComponentResult,
  options: RSCRenderParams,
  streamingTrackers: StreamingTrackers,
): Readable => {
  const { throwJsErrors } = options;
  const { railsContext } = options;
  assertRailsContextWithServerStreamingCapabilities(railsContext);

  const { reactClientManifestFileName } = railsContext;
  const renderState: StreamRenderState = {
    result: null,
    hasErrors: false,
    isShellReady: true,
  };

  const { pipeToTransform, readableStream, emitError, writeChunk, endStream } =
    transformRenderStreamChunksToResultObject(renderState);

  const reportError = (error: Error) => {
    console.error('Error in RSC stream', error);
    if (throwJsErrors) {
      emitError(error);
    }
    renderState.hasErrors = true;
    renderState.error = error;
  };

  const initializeAndRender = async () => {
    if (!serverRendererPromise) {
      serverRendererPromise = loadJsonFile<BundleManifest>(reactClientManifestFileName)
        .then((reactClientManifest) => buildServerRenderer(reactClientManifest))
        .catch((err: unknown) => {
          serverRendererPromise = undefined;
          throw err;
        });
    }

    const { renderToPipeableStream } = await serverRendererPromise;
    const rscStream = renderToPipeableStream(await reactRenderingResult, {
      onError: (err) => {
        const error = convertToError(err);
        reportError(error);
      },
    });
    pipeToTransform(rscStream);
  };

  initializeAndRender().catch((e: unknown) => {
    const error = convertToError(e);
    reportError(error);
    const errorHtml = handleError({ e: error, name: options.name, serverSide: true });
    writeChunk(errorHtml);
    endStream();
  });

  readableStream.on('end', () => {
    streamingTrackers.postSSRHookTracker.notifySSREnd();
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

export * from './types/index.ts';
export default ReactOnRails;
