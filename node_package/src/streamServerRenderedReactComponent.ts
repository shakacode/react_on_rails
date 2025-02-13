import ReactDOMServer, { type PipeableStream } from 'react-dom/server';
import { PassThrough, Readable } from 'stream';
import type { ReactElement } from 'react';
import injectRSCPayload from './injectRSCPayload';

import ComponentRegistry from './ComponentRegistry';
import createReactOutput from './createReactOutput';
import { isPromise, isServerRenderHash } from './isServerRenderResult';
import buildConsoleReplay from './buildConsoleReplay';
import handleError from './handleError';
import { createResultObject, convertToError, validateComponent } from './serverRenderUtils';
import type { RenderParams, StreamRenderParams, StreamRenderState } from './types';

const stringToStream = (str: string): Readable => {
  const stream = new PassThrough();
  stream.write(str);
  stream.end();
  return stream;
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
    }
  });

  let pipedStream: PipeableStream | PassThrough | null = null;
  const pipeToTransform = (pipeableStream: PipeableStream | PassThrough) => {
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
    if (pipedStream && 'end' in pipedStream) {
      pipedStream.end();
    } else if (pipedStream) {
      pipedStream.abort();
    }
  }
  return { readableStream, pipeToTransform, writeChunk, emitError, endStream };
}

const streamRenderReactComponent = (reactRenderingResult: ReactElement, options: StreamRenderParams) => {
  const { name: componentName, throwJsErrors, rscResult } = options;
  const renderState: StreamRenderState = {
    result: null,
    hasErrors: false,
    isShellReady: false
  };

  const {
    readableStream,
    pipeToTransform,
    writeChunk,
    emitError,
    endStream
  } = transformRenderStreamChunksToResultObject(renderState);

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
      if (rscResult) {
        pipeToTransform(injectRSCPayload(renderingStream, rscResult));
      } else {
        pipeToTransform(renderingStream);
      }
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
}

type StreamRenderer<T, P extends RenderParams> = (
  reactElement: ReactElement,
  options: P,
) => T;

export const streamServerRenderedComponent = <T, P extends RenderParams>(
  options: P,
  renderStrategy: StreamRenderer<T, P>
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
    const jsonResult = JSON.stringify(createResultObject(htmlResult, buildConsoleReplay(), { hasErrors: true, error, result: null }));
    return stringToStream(jsonResult) as T;
  }
};

const streamServerRenderedReactComponent = (options: StreamRenderParams): Readable => {
  const { rscResult, reactClientManifestFileName, reactServerManifestFileName } = options;
  let rscResult1;
  let rscResult2;
  if (typeof rscResult === 'object') {
    rscResult1 = new PassThrough();
    rscResult.pipe(rscResult1);
    rscResult2 = new PassThrough();
    rscResult.pipe(rscResult2);
  }
  return streamServerRenderedComponent({
    ...options,
    rscResult: rscResult1,
    props: { ...options.props, getRscPromise: rscResult2, reactClientManifestFileName, reactServerManifestFileName }
  }, streamRenderReactComponent);
}

export default streamServerRenderedReactComponent;
