import ReactDOMServer from 'react-dom/server';

import ComponentRegistry from './ComponentRegistry';
import createReactElement from './createReactElement';
import isCreateReactElementResultNonReactComponent from
  './isCreateReactElementResultNonReactComponent';
import buildConsoleReplay from './buildConsoleReplay';
import handleError from './handleError';

export default function serverRenderReactComponent(options) {
  const { name, domNodeId, trace, props, railsContext } = options;

  let htmlResult = '';
  let hasErrors = false;

  try {
    const componentObj = ComponentRegistry.get(name);
    if (componentObj.isRenderer) {
      throw new Error(`\
Detected a renderer while server rendering component '${name}'. \
See https://github.com/shakacode/react_on_rails#renderer-functions`);
    }

    const reactElementOrRouterResult = createReactElement({
      componentObj,
      domNodeId,
      trace,
      props,
      railsContext,
    });

    if (isCreateReactElementResultNonReactComponent(reactElementOrRouterResult)) {
      // We let the client side handle any redirect
      // Set hasErrors in case we want to throw a Rails exception
      hasErrors = !!reactElementOrRouterResult.routeError;

      if (hasErrors) {
        console.error(
          `React Router ERROR: ${JSON.stringify(reactElementOrRouterResult.routeError)}`,
        );
      }

      if (reactElementOrRouterResult.redirectLocation) {
        if (trace) {
          const { redirectLocation } = reactElementOrRouterResult;
          const redirectPath = redirectLocation.pathname + redirectLocation.search;
          console.log(`\
ROUTER REDIRECT: ${name} to dom node with id: ${domNodeId}, redirect to ${redirectPath}`,
          );
        }
        // For redirects on server rendering, we can't stop Rails from returning the same result.
        // Possibly, someday, we could have the rails server redirect.
      } else {
        htmlResult = reactElementOrRouterResult.renderedHtml;
      }
    } else {
      htmlResult = ReactDOMServer.renderToString(reactElementOrRouterResult);
    }
  } catch (e) {
    hasErrors = true;
    htmlResult = handleError({
      e,
      name,
      serverSide: true,
    });
  }

  const consoleReplayScript = buildConsoleReplay();

  return JSON.stringify({
    html: htmlResult,
    consoleReplayScript,
    hasErrors,
  });
}
