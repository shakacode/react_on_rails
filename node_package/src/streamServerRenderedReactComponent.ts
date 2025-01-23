import ReactDOMServer, { type PipeableStream } from 'react-dom/server';
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

const transformRenderStreamChunksToResultObject = (renderState: StreamRenderState) => {
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

  let pipedStream: PipeableStream | null = null;
  const pipeToTransform = (pipeableStream: PipeableStream) => {
    pipeableStream.pipe(transformStream);
    pipedStream = pipeableStream;
  };
  // We need to wrap the transformStream in a Readable stream to properly handle errors:
  // 1. If we returned transformStream directly, we couldn't emit errors into it externally
  // 2. If an error is emitted into the transformStream, it would cause the render to fail
  // 3. By wrapping in Readable.from(), we can explicitly emit errors into the readableStream without affecting the transformStream
  // Note: Readable.from can merge multiple chunks into a single chunk, so we need to ensure that we can separate them later
  const readableStream = Readable.from(transformStream);

  const writeChunk = (chunk: string) => transformStream.write(chunk);
  const emitError = (error: unknown) => readableStream.emit('error', error);
  const endStream = () => {
    transformStream.end();
    pipedStream?.abort();
  };
  return { readableStream, pipeToTransform, writeChunk, emitError, endStream };
};

const streamRenderReactComponent = (reactRenderingResult: ReactElement, options: RenderParams) => {
  const { name: componentName, throwJsErrors } = options;
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
  });

  return readableStream;
};

const streamServerRenderedReactComponent = (options: RenderParams): Readable => {
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

    return streamRenderReactComponent(reactRenderingResult, options);
  } catch (e) {
    if (throwJsErrors) {
      throw e;
    }

    const error = convertToError(e);
    const htmlResult = handleError({ e: error, name: componentName, serverSide: true });
    const jsonResult = JSON.stringify(
      createResultObject(htmlResult, buildConsoleReplay(), { hasErrors: true, error, result: null }),
    );
    return stringToStream(jsonResult);
  }
};

export default streamServerRenderedReactComponent;
