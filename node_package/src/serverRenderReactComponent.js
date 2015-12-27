import ReactDOMServer from 'react-dom/server';
import createReactElement from './createReactElement';

import isRouterResult from './isRouterResult';
import buildConsoleReplay from './buildConsoleReplay';
import handleError from './handleError';

export default function serverRenderReactComponent(options) {
  const componentName = options.componentName;
  const domId = options.domId;
  const props = options.props;
  const trace = options.trace;
  const generatorFunction = options.generatorFunction;
  const location = options.location;
  let htmlResult = '';
  let hasErrors = false;

  try {
    const reactElementOrRouterResult = createReactElement({
      componentName, props, domId, trace, generatorFunction, location });
    if (isRouterResult(reactElementOrRouterResult)) {
      // We let the client side handle any redirect
      // Set hasErrors in case we want to throw a Rails exception
      hasErrors = !!reactElementOrRouterResult.routeError;
      if (hasErrors) {
        console.error('React Router ERROR: ' +
          JSON.stringify(reactElementOrRouterResult.routeError));
      } else {
        if (trace) {
          const redirectLocation = reactElementOrRouterResult.redirectLocation;
          const redirectPath = redirectLocation.pathname + redirectLocation.search;
          console.log('ROUTER REDIRECT: ' + componentName + ' to dom node with id: ' + domId +
            ', redirect to ' + redirectPath);
        }
      }
    } else {
      htmlResult = ReactDOMServer.renderToString(reactElementOrRouterResult);
    }
  } catch (e) {
    hasErrors = true;
    htmlResult = handleError({
      e,
      componentName,
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
