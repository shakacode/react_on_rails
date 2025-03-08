import * as ReactDOMServer from 'react-dom/server';
import { PassThrough, Readable } from 'stream';
import type { ReactElement } from 'react';

import ComponentRegistry from './ComponentRegistry';
import createReactOutput from './createReactOutput';
import { isPromise, isServerRenderHash } from './isServerRenderResult';
import buildConsoleReplay from './buildConsoleReplay';
import handleError from './handleError';
import { createResultObject, convertToError, validateComponent } from './serverRenderUtils';
import type { RenderParams, StreamRenderState } from './types';

const stringToStream = (str: string): Readable => {
  const stream = new PassThrough();
  stream.write(str);
  stream.end();
  return stream;
};

type BufferdEvent = {
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
  const bufferedEvents: BufferdEvent[] = [];
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
      const handleEvent = ({ event, data }: BufferdEvent) => {
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
    transform(chunk, _, callback) {
      const htmlChunk = chunk.toString();
      const consoleReplayScript = buildConsoleReplay(consoleHistory, previouslyReplayedConsoleMessages);
      previouslyReplayedConsoleMessages = consoleHistory?.length || 0;

      const jsonChunk = JSON.stringify(createResultObject(htmlChunk, consoleReplayScript, renderState));

      this.push(`${jsonChunk}\n`);
      callback();
    },
  });

  let pipedStream: ReactDOMServer.PipeableStream | null = null;
  const pipeToTransform = (pipeableStream: ReactDOMServer.PipeableStream) => {
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
    pipedStream?.abort();
  };
  return { readableStream, pipeToTransform, writeChunk, emitError, endStream };
};

const streamRenderReactComponent = (reactRenderingResult: ReactElement, options: RenderParams) => {
  const { name: componentName, throwJsErrors, domNodeId } = options;
  const renderState: StreamRenderState = {
    result: null,
    hasErrors: false,
    isShellReady: false,
  };

  const { readableStream, pipeToTransform, writeChunk, emitError, endStream } =
    transformRenderStreamChunksToResultObject(renderState);

  const renderingStream = ReactDOMServer.renderToPipeableStream(reactRenderingResult, {
    onShellError(e) {
      const error = convertToError(e);
      renderState.hasErrors = true;
      renderState.error = error;

      if (throwJsErrors) {
        emitError(error);
      }

      const errorHtml = handleError({ e: error, name: componentName, serverSide: true });
      writeChunk(errorHtml);
      endStream();
    },
    onShellReady() {
      renderState.isShellReady = true;
      pipeToTransform(renderingStream);
    },
    onError(e) {
      if (!renderState.isShellReady) {
        return;
      }
      const error = convertToError(e);
      if (throwJsErrors) {
        emitError(error);
      }
      renderState.hasErrors = true;
      renderState.error = error;
    },
    identifierPrefix: domNodeId,
  });

  return readableStream;
};

type StreamRenderer<T, P extends RenderParams> = (reactElement: ReactElement, options: P) => T;

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

    if (isServerRenderHash(reactRenderingResult) || isPromise(reactRenderingResult)) {
      throw new Error('Server rendering of streams is not supported for server render hashes or promises.');
    }

    return renderStrategy(reactRenderingResult, options);
  } catch (e) {
    if (throwJsErrors) {
      throw e;
    }

    const error = convertToError(e);
    const htmlResult = handleError({ e: error, name: componentName, serverSide: true });
    const jsonResult = JSON.stringify(
      createResultObject(htmlResult, buildConsoleReplay(), { hasErrors: true, error, result: null }),
    );
    return stringToStream(jsonResult) as T;
  }
};

const streamServerRenderedReactComponent = (options: RenderParams): Readable =>
  streamServerRenderedComponent(options, streamRenderReactComponent);

export default streamServerRenderedReactComponent;
