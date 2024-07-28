import ReactDOMServer from 'react-dom/server';
import { PassThrough } from 'stream';
import type { ReactElement } from 'react';

import ComponentRegistry from './ComponentRegistry';
import createReactOutput from './createReactOutput';
import { isServerRenderHash, isPromise } from './isServerRenderResult';
import buildConsoleReplay from './buildConsoleReplay';
import handleError from './handleError';
import type { RenderParams, RenderResult, RenderingError } from './types/index';

/* eslint-disable @typescript-eslint/no-explicit-any */

function serverRenderReactComponentInternal(options: RenderParams): null | string | Promise<RenderResult> {
  const { name, domNodeId, trace, props, railsContext, renderingReturnsPromises, throwJsErrors } = options;

  let renderResult: null | string | Promise<string> = null;
  let hasErrors = false;
  let renderingError: null | RenderingError = null;

  try {
    const componentObj = ComponentRegistry.get(name);
    if (componentObj.isRenderer) {
      throw new Error(`\
Detected a renderer while server rendering component '${name}'. \
See https://github.com/shakacode/react_on_rails#renderer-functions`);
    }

    const reactRenderingResult = createReactOutput({
      componentObj,
      domNodeId,
      trace,
      props,
      railsContext,
    });

    const processServerRenderHash = () => {
        // We let the client side handle any redirect
        // Set hasErrors in case we want to throw a Rails exception
        hasErrors = !!(reactRenderingResult as {routeError: Error}).routeError;

        if (hasErrors) {
          console.error(
            `React Router ERROR: ${JSON.stringify((reactRenderingResult as {routeError: Error}).routeError)}`,
          );
        }

        if ((reactRenderingResult as {redirectLocation: {pathname: string; search: string}}).redirectLocation) {
          if (trace) {
            const { redirectLocation } = (reactRenderingResult as {redirectLocation: {pathname: string; search: string}});
            const redirectPath = redirectLocation.pathname + redirectLocation.search;
            console.log(`\
  ROUTER REDIRECT: ${name} to dom node with id: ${domNodeId}, redirect to ${redirectPath}`,
            );
          }
          // For redirects on server rendering, we can't stop Rails from returning the same result.
          // Possibly, someday, we could have the rails server redirect.
          return '';
        }
        return (reactRenderingResult as { renderedHtml: string }).renderedHtml;
    };

    const processPromise = () => {
      if (!renderingReturnsPromises) {
        console.error('Your render function returned a Promise, which is only supported by a node renderer, not ExecJS.')
      }
      return reactRenderingResult;
    }

    const processReactElement = () => {
      try {
        return ReactDOMServer.renderToString(reactRenderingResult as ReactElement);
      } catch (error) {
        console.error(`Invalid call to renderToString. Possibly you have a renderFunction, a function that already
calls renderToString, that takes one parameter. You need to add an extra unused parameter to identify this function
as a renderFunction and not a simple React Function Component.`);
        throw error;
      }
    };

    if (isServerRenderHash(reactRenderingResult)) {
      renderResult = processServerRenderHash();
    } else if (isPromise(reactRenderingResult)) {
      renderResult = processPromise() as Promise<string>;
    } else {
      renderResult = processReactElement();
    }
  } catch (e: any) {
    if (throwJsErrors) {
      throw e;
    }

    hasErrors = true;
    renderResult = handleError({
      e,
      name,
      serverSide: true,
    });
    renderingError = e;
  }

  const consoleHistoryAfterSyncExecution = console.history;
  const addRenderingErrors = (resultObject: RenderResult, renderError: RenderingError) => {
    resultObject.renderingError = { // eslint-disable-line no-param-reassign
      message: renderError.message,
      stack: renderError.stack,
    };
  }

  if(renderingReturnsPromises) {
    const resolveRenderResult = async () => {
      let promiseResult;

      try {
        const awaitedRenderResult = await renderResult;

        // If replayServerAsyncOperationLogs node renderer config is enabled, the console.history will contain all logs happened during sync and async operations.
        // If the config is disabled, the console.history will be empty, because it will clear the history after the sync execution.
        // In case of disabled config, we will use the console.history after sync execution, which contains all logs happened during sync execution.
        const consoleHistoryAfterAsyncExecution = console.history;
        let consoleReplayScript = '';
        if ((consoleHistoryAfterAsyncExecution?.length ?? 0) > (consoleHistoryAfterSyncExecution?.length ?? 0)) {
          consoleReplayScript = buildConsoleReplay(consoleHistoryAfterAsyncExecution);
        } else {
          consoleReplayScript = buildConsoleReplay(consoleHistoryAfterSyncExecution);
        }

        promiseResult = {
          html: awaitedRenderResult,
          consoleReplayScript,
          hasErrors,
        };
      } catch (e: any) {
        if (throwJsErrors) {
          throw e;
        }
        promiseResult = {
          html: handleError({
            e,
            name,
            serverSide: true,
          }),
          consoleReplayScript: buildConsoleReplay(consoleHistoryAfterSyncExecution),
          hasErrors: true,
        }
        renderingError = e;
      }

      if (renderingError !== null) {
        addRenderingErrors(promiseResult, renderingError);
      }

      return promiseResult;
    };

    return resolveRenderResult();
  }

  const result = {
    html: renderResult,
    consoleReplayScript: buildConsoleReplay(consoleHistoryAfterSyncExecution),
    hasErrors,
  } as RenderResult;

  if (renderingError) {
    addRenderingErrors(result, renderingError);
  }

  return JSON.stringify(result);
}

const serverRenderReactComponent: typeof serverRenderReactComponentInternal = (options) => {
  let result: string | Promise<RenderResult> | null = null;
  try {
    result = serverRenderReactComponentInternal(options);
  } finally {
    // Reset console history after each render.
    // See `RubyEmbeddedJavaScript.console_polyfill` for initialization.
    // We don't need to clear the console history if the result is a promise
    // Promises only supported in node renderer and node renderer takes care of cleanining console history
    if (typeof result === 'string') {
      console.history = [];
    }
  }
  return result;
};

const stringToStream = (str: string) => {
  const stream = new PassThrough();
  stream.push(str);
  stream.push(null);
  return stream;
};

export const streamServerRenderedReactComponent = (options: RenderParams) => {
  const { name, domNodeId, trace, props, railsContext, throwJsErrors } = options;

  let renderResult: null | PassThrough = null;

  try {
    const componentObj = ComponentRegistry.get(name);
    if (componentObj.isRenderer) {
      throw new Error(`\
Detected a renderer while server rendering component '${name}'. \
See https://github.com/shakacode/react_on_rails#renderer-functions`);
    }

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

    renderResult = new PassThrough();
    ReactDOMServer.renderToPipeableStream(reactRenderingResult).pipe(renderResult);

    // TODO: Add console replay script to the stream
    // Ensure to avoid console messages leaking between different components rendering
  } catch (e: any) {
    if (throwJsErrors) {
      throw e;
    }

    renderResult = stringToStream(handleError({
      e,
      name,
      serverSide: true,
    }));
  }

  return renderResult;
};

export default serverRenderReactComponent;
