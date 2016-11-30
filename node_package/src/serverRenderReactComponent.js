import ReactDOMServer from 'react-dom/server';

import ComponentRegistry from './ComponentRegistry';
import createReactElement from './createReactElement';
import isRouterResult from './isRouterResult';
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

    if (isRouterResult(reactElementOrRouterResult)) {
      // We let the client side handle any redirect
      // Set hasErrors in case we want to throw a Rails exception
      hasErrors = !!reactElementOrRouterResult.routeError;
      if (hasErrors) {
        console.error(
          `React Router ERROR: ${JSON.stringify(reactElementOrRouterResult.routeError)}`,
        );
      } else if (trace) {
        const redirectLocation = reactElementOrRouterResult.redirectLocation;
        const redirectPath = redirectLocation.pathname + redirectLocation.search;
        console.log(`\
ROUTER REDIRECT: ${name} to dom node with id: ${domNodeId}, redirect to ${redirectPath}`,
        );
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
