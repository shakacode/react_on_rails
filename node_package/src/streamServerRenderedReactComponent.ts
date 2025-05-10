import * as React from 'react';
import { PassThrough, Readable } from 'stream';

import * as ComponentRegistry from './ComponentRegistry.ts';
import createReactOutput from './createReactOutput.ts';
import { isPromise, isServerRenderHash } from './isServerRenderResult.ts';
import buildConsoleReplay from './buildConsoleReplay.ts';
import handleError from './handleError.ts';
import { renderToPipeableStream, PipeableStream } from './ReactDOMServer.cts';
import { createResultObject, convertToError, validateComponent } from './serverRenderUtils.ts';
import type {
  RailsContextWithComponentSpecificMetadata,
  RenderParams,
  StreamRenderState,
  StreamableComponentResult,
} from './types/index.ts';
import injectRSCPayload from './injectRSCPayload.ts';
import { notifySSREnd } from './postSSRHooks.ts';

type BufferedEvent = {
  event: 'data' | 'error' | 'end';
  data: unknown;
};

/**
 * Creates a new Readable stream that safely buffers all events from the input stream until reading begins.
 *
 * This function solves two important problems:
 * 1. Error handling: If an error occurs on the source stream before error listeners are attached,
 *    it would normally crash the process. This wrapper buffers error events until reading begins,
 *    ensuring errors are properly handled once listeners are ready.
 * 2. Event ordering: All events (data, error, end) are buffered and replayed in the exact order
 *    they were received, maintaining the correct sequence even if events occur before reading starts.
 *
 * @param stream - The source Readable stream to buffer
 * @returns {Object} An object containing:
 *   - stream: A new Readable stream that will buffer and replay all events
 *   - emitError: A function to manually emit errors into the stream
 */
const bufferStream = (stream: Readable) => {
  const bufferedEvents: BufferedEvent[] = [];
  let startedReading = false;

  const listeners = (['data', 'error', 'end'] as const).map((event) => {
    const listener = (data: unknown) => {
      if (!startedReading) {
        bufferedEvents.push({ event, data });
      }
    };
    stream.on(event, listener);
    return { event, listener };
  });

  const bufferedStream = new Readable({
    read() {
      if (startedReading) return;
      startedReading = true;

      // Remove initial listeners
      listeners.forEach(({ event, listener }) => stream.off(event, listener));
      const handleEvent = ({ event, data }: BufferedEvent) => {
        if (event === 'data') {
          this.push(data);
        } else if (event === 'error') {
          this.emit('error', data);
        } else {
          this.push(null);
        }
      };

      // Replay buffered events
      bufferedEvents.forEach(handleEvent);

      // Attach new listeners for future events
      (['data', 'error', 'end'] as const).forEach((event) => {
        stream.on(event, (data: unknown) => handleEvent({ event, data }));
      });
    },
  });

  return {
    stream: bufferedStream,
    emitError: (error: unknown) => {
      if (startedReading) {
        bufferedStream.emit('error', error);
      } else {
        bufferedEvents.push({ event: 'error', data: error });
      }
    },
  };
};

export const transformRenderStreamChunksToResultObject = (renderState: StreamRenderState) => {
  const consoleHistory = console.history;
  let previouslyReplayedConsoleMessages = 0;

  const transformStream = new PassThrough({
    transform(chunk: Buffer, _, callback) {
      const htmlChunk = chunk.toString();
      const consoleReplayScript = buildConsoleReplay(consoleHistory, previouslyReplayedConsoleMessages);
      previouslyReplayedConsoleMessages = consoleHistory?.length || 0;
      const jsonChunk = JSON.stringify(createResultObject(htmlChunk, consoleReplayScript, renderState));
      this.push(`${jsonChunk}\n`);

      // Reset the render state to ensure that the error is not carried over to the next chunk
      // eslint-disable-next-line no-param-reassign
      renderState.error = undefined;
      // eslint-disable-next-line no-param-reassign
      renderState.hasErrors = false;

      callback();
    },
  });

  let pipedStream: PipeableStream | NodeJS.ReadableStream | null = null;
  const pipeToTransform = (pipeableStream: PipeableStream | NodeJS.ReadableStream) => {
    pipeableStream.pipe(transformStream);
    pipedStream = pipeableStream;
  };
  // We need to wrap the transformStream in a Readable stream to properly handle errors:
  // 1. If we returned transformStream directly, we couldn't emit errors into it externally
  // 2. If an error is emitted into the transformStream, it would cause the render to fail
  // 3. By wrapping in Readable.from(), we can explicitly emit errors into the readableStream without affecting the transformStream
  // Note: Readable.from can merge multiple chunks into a single chunk, so we need to ensure that we can separate them later
  const { stream: readableStream, emitError } = bufferStream(transformStream);

  const writeChunk = (chunk: string) => transformStream.write(chunk);
  const endStream = () => {
    transformStream.end();
    if (pipedStream && 'abort' in pipedStream) {
      pipedStream.abort();
    }
  };
  return { readableStream, pipeToTransform, writeChunk, emitError, endStream };
};

const streamRenderReactComponent = (
  reactRenderingResult: StreamableComponentResult,
  options: RenderParams,
) => {
  const { name: componentName, throwJsErrors, domNodeId } = options;
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
    const errorHtml = handleError({ e: error, name: componentName, serverSide: true });
    writeChunk(errorHtml);
    endStream();
  };

  const { railsContext } = options;
  if (!railsContext) {
    throw new Error('railsContext is required to stream a React component');
  }

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
          pipeToTransform(injectRSCPayload(renderingStream, railsContext));
        },
        onError(e) {
          reportError(convertToError(e));
        },
        onAllReady() {
          if (railsContext.componentSpecificMetadata?.renderRequestId) {
            notifySSREnd(railsContext as RailsContextWithComponentSpecificMetadata);
          }
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

type StreamRenderer<T, P extends RenderParams> = (reactElement: StreamableComponentResult, options: P) => T;

export const streamServerRenderedComponent = <T, P extends RenderParams>(
  options: P,
  renderStrategy: StreamRenderer<T, P>,
): T => {
  const { name: componentName, domNodeId, trace, props, railsContext, throwJsErrors } = options;

  try {
    const componentObj = ComponentRegistry.get(componentName);
    validateComponent(componentObj, componentName);

    const reactRenderingResult = createReactOutput({
      componentObj,
      domNodeId,
      trace,
      props,
      railsContext,
    });

    if (isServerRenderHash(reactRenderingResult)) {
      throw new Error('Server rendering of streams is not supported for server render hashes.');
    }

    if (isPromise(reactRenderingResult)) {
      const promiseAfterRejectingHash = reactRenderingResult.then((result) => {
        if (!React.isValidElement(result)) {
          throw new Error(
            `Invalid React element detected while rendering ${componentName}. If you are trying to stream a component registered as a render function, ` +
              `please ensure that the render function returns a valid React component, not a server render hash. ` +
              `This error typically occurs when the render function does not return a React element or returns an incorrect type.`,
          );
        }
        return result;
      });
      return renderStrategy(promiseAfterRejectingHash, options);
    }

    return renderStrategy(reactRenderingResult, options);
  } catch (e) {
    const { readableStream, writeChunk, emitError, endStream } = transformRenderStreamChunksToResultObject({
      hasErrors: true,
      isShellReady: false,
      result: null,
    });
    if (throwJsErrors) {
      emitError(e);
    }

    const error = convertToError(e);
    const htmlResult = handleError({ e: error, name: componentName, serverSide: true });
    writeChunk(htmlResult);
    endStream();
    return readableStream as T;
  }
};

const streamServerRenderedReactComponent = (options: RenderParams): Readable =>
  streamServerRenderedComponent(options, streamRenderReactComponent);

export default streamServerRenderedReactComponent;
