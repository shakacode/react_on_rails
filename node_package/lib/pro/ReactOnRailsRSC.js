/*
 * Copyright (c) 2025 Shakacode LLC
 *
 * This file is NOT licensed under the MIT (open source) license.
 * It is part of the React on Rails Pro offering and is licensed separately.
 *
 * Unauthorized copying, modification, distribution, or use of this file,
 * via any medium, is strictly prohibited without a valid license agreement
 * from Shakacode LLC.
 *
 * For licensing terms, please see:
 * https://github.com/shakacode/react_on_rails/blob/master/REACT-ON-RAILS-PRO-LICENSE.md
 */
import { buildServerRenderer } from 'react-on-rails-rsc/server.node';
import { assertRailsContextWithServerStreamingCapabilities } from '../types/index.js';
import ReactOnRails from '../ReactOnRails.full.js';
import handleError from '../handleError.js';
import { convertToError } from '../serverRenderUtils.js';
import {
  streamServerRenderedComponent,
  transformRenderStreamChunksToResultObject,
} from './streamServerRenderedReactComponent.js';
import loadJsonFile from '../loadJsonFile.js';

let serverRendererPromise;
const streamRenderRSCComponent = (reactRenderingResult, options, streamingTrackers) => {
  const { throwJsErrors } = options;
  const { railsContext } = options;
  assertRailsContextWithServerStreamingCapabilities(railsContext);
  const { reactClientManifestFileName } = railsContext;
  const renderState = {
    result: null,
    hasErrors: false,
    isShellReady: true,
  };
  const { pipeToTransform, readableStream, emitError, writeChunk, endStream } =
    transformRenderStreamChunksToResultObject(renderState);
  const reportError = (error) => {
    console.error('Error in RSC stream', error);
    if (throwJsErrors) {
      emitError(error);
    }
    renderState.hasErrors = true;
    renderState.error = error;
  };
  const initializeAndRender = async () => {
    if (!serverRendererPromise) {
      serverRendererPromise = loadJsonFile(reactClientManifestFileName)
        .then((reactClientManifest) => buildServerRenderer(reactClientManifest))
        .catch((err) => {
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
  initializeAndRender().catch((e) => {
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
ReactOnRails.serverRenderRSCReactComponent = (options) => {
  try {
    return streamServerRenderedComponent(options, streamRenderRSCComponent);
  } finally {
    console.history = [];
  }
};
ReactOnRails.isRSCBundle = true;
export * from '../types/index.js';
export default ReactOnRails;
