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

import { Readable } from 'stream';

import { renderToPipeableStream } from 'react-on-rails/ReactDOMServer';
import { convertToError } from 'react-on-rails/serverRenderUtils';
import {
  assertRailsContextWithServerStreamingCapabilities,
  RenderParams,
  StreamRenderState,
  StreamableComponentResult,
} from 'react-on-rails/types';
import injectRSCPayload from './injectRSCPayload.ts';
import {
  streamServerRenderedComponent,
  StreamingTrackers,
  transformRenderStreamChunksToResultObject,
} from './streamingUtils.ts';
import handleError from './handleError.ts';

const streamRenderReactComponent = (
  reactRenderingResult: StreamableComponentResult,
  options: RenderParams,
  streamingTrackers: StreamingTrackers,
) => {
  const { name: componentName, throwJsErrors, domNodeId, railsContext } = options;
  const renderState: StreamRenderState = {
    result: null,
    hasErrors: false,
    isShellReady: false,
  };

  const { readableStream, pipeToTransform, writeChunk, emitError, endStream } =
    transformRenderStreamChunksToResultObject(renderState);

  const reportError = (error: Error) => {
    renderState.hasErrors = true;
    renderState.error = error;

    if (throwJsErrors) {
      emitError(error);
    }
  };

  const sendErrorHtml = (error: Error) => {
    const errorHtmlStream = handleError({ e: error, name: componentName, serverSide: true });
    pipeToTransform(errorHtmlStream);
  };

  assertRailsContextWithServerStreamingCapabilities(railsContext);

  Promise.resolve(reactRenderingResult)
    .then((reactRenderedElement) => {
      if (typeof reactRenderedElement === 'string') {
        console.error(
          `Error: stream_react_component helper received a string instead of a React component for component "${componentName}".\n` +
            'To benefit from React on Rails Pro streaming feature, your render function should return a React component.\n' +
            'Do not call ReactDOMServer.renderToString() inside the render function as this defeats the purpose of streaming.\n',
        );

        writeChunk(reactRenderedElement);
        endStream();
        return;
      }

      const renderingStream = renderToPipeableStream(reactRenderedElement, {
        onShellError(e) {
          sendErrorHtml(convertToError(e));
        },
        onShellReady() {
          renderState.isShellReady = true;
          pipeToTransform(
            injectRSCPayload(
              renderingStream,
              streamingTrackers.rscRequestTracker,
              domNodeId,
              railsContext.cspNonce,
            ),
          );
        },
        onError(e) {
          reportError(convertToError(e));
        },
        onAllReady() {
          streamingTrackers.postSSRHookTracker.notifySSREnd();
        },
        identifierPrefix: domNodeId,
      });
    })
    .catch((e: unknown) => {
      const error = convertToError(e);
      reportError(error);
      sendErrorHtml(error);
    });
  return readableStream;
};

const streamServerRenderedReactComponent = (options: RenderParams): Readable =>
  streamServerRenderedComponent(options, streamRenderReactComponent, handleError);

export default streamServerRenderedReactComponent;
