import ReactDOMServer from 'react-dom/server';
import type { ReactElement } from 'react';

import ComponentRegistry from './ComponentRegistry';
import createReactOutput from './createReactOutput';
import {isServerRenderHash, isPromise} from
    './isServerRenderResult';
import buildConsoleReplay from './buildConsoleReplay';
import handleError from './handleError';
import type { RenderParams, RenderResult, RenderingError } from './types/index';

export default function serverRenderReactComponent(options: RenderParams): null | string | Promise<RenderResult> {
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
  } catch (e) {
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

  const consoleReplayScript = buildConsoleReplay();
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
        promiseResult = {
          html: await renderResult,
          consoleReplayScript,
          hasErrors,
        };
      } catch (e) {
        if (throwJsErrors) {
          throw e;
        }
        promiseResult = {
          html: handleError({
            e,
            name,
            serverSide: true,
          }),
          consoleReplayScript,
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
    consoleReplayScript,
    hasErrors,
  } as RenderResult;

  if (renderingError) {
    addRenderingErrors(result, renderingError);
  }

  return JSON.stringify(result);
}
