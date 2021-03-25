import ReactDOMServer from 'react-dom/server';
import type { ReactElement } from 'react';

import ComponentRegistry from './ComponentRegistry';
import createReactOutput from './createReactOutput';
import isCreateReactElementResultNonReactComponent from
    './isServerRenderResult';
import buildConsoleReplay from './buildConsoleReplay';
import handleError from './handleError';
import type { RenderParams, RenderResult } from './types/index';

export default function serverRenderReactComponent(options: RenderParams): string {
  const { name, domNodeId, trace, props, railsContext, throwJsErrors } = options;

  let htmlResult = '';
  let hasErrors = false;
  let renderingError = null;

  try {
    const componentObj = ComponentRegistry.get(name);
    if (componentObj.isRenderer) {
      throw new Error(`\
Detected a renderer while server rendering component '${name}'. \
See https://github.com/shakacode/react_on_rails#renderer-functions`);
    }

    const reactElementOrRouterResult = createReactOutput({
      componentObj,
      domNodeId,
      trace,
      props,
      railsContext,
    });

    if (isCreateReactElementResultNonReactComponent(reactElementOrRouterResult)) {
      // We let the client side handle any redirect
      // Set hasErrors in case we want to throw a Rails exception
      hasErrors = !!(reactElementOrRouterResult as {routeError: Error}).routeError;

      if (hasErrors) {
        console.error(
          `React Router ERROR: ${JSON.stringify((reactElementOrRouterResult as {routeError: Error}).routeError)}`,
        );
      }

      if ((reactElementOrRouterResult as {redirectLocation: {pathname: string; search: string}}).redirectLocation) {
        if (trace) {
          const { redirectLocation } = (reactElementOrRouterResult as {redirectLocation: {pathname: string; search: string}});
          const redirectPath = redirectLocation.pathname + redirectLocation.search;
          console.log(`\
ROUTER REDIRECT: ${name} to dom node with id: ${domNodeId}, redirect to ${redirectPath}`,
          );
        }
        // For redirects on server rendering, we can't stop Rails from returning the same result.
        // Possibly, someday, we could have the rails server redirect.
      } else {
        htmlResult = (reactElementOrRouterResult as { renderedHtml: string }).renderedHtml;
      }
    } else {
      try {
        htmlResult = ReactDOMServer.renderToString(reactElementOrRouterResult as ReactElement);
      } catch (error) {
        console.error(
            `Invalid call to renderToString. Possibly you have a renderFunction, a function that already
calls renderToString, that takes one parameter. You need to add an extra unused
parameter to identify this function as a renderFunction and not a simple React 
Function Component.`);
        throw error;
      }
    }
  } catch (e) {
    if (throwJsErrors) {
      throw e;
    }

    hasErrors = true;
    htmlResult = handleError({
      e,
      name,
      serverSide: true,
    });
    renderingError = e;
  }

  const consoleReplayScript = buildConsoleReplay();

  const result = {
    html: htmlResult,
    consoleReplayScript,
    hasErrors,
  } as RenderResult;

  if (renderingError) {
    result.renderingError = {
      message: renderingError.message,
      stack: renderingError.stack,
    }
  }

  return JSON.stringify(result);
}
