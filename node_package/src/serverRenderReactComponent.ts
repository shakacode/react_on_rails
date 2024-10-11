import ReactDOMServer from 'react-dom/server';
import type { ReactElement } from 'react';

import ComponentRegistry from './ComponentRegistry';
import createReactOutput from './createReactOutput';
import { isPromise, isServerRenderHash } from './isServerRenderResult';
import buildConsoleReplay from './buildConsoleReplay';
import handleError from './handleError';
import type { CreateReactOutputResult, RegisteredComponent, RenderParams, RenderResult, RenderingError, ServerRenderResult } from './types';

type RenderState = {
  result: null | string | Promise<string>;
  hasErrors: boolean;
  error: null | RenderingError;
};

type RenderOptions = {
  name: string;
  domNodeId?: string;
  trace?: boolean;
  renderingReturnsPromises: boolean;
};

function validateComponent(componentObj: RegisteredComponent, name: string) {
  if (componentObj.isRenderer) {
    throw new Error(`Detected a renderer while server rendering component '${name}'. See https://github.com/shakacode/react_on_rails#renderer-functions`);
  }
}

function processServerRenderHash(result: ServerRenderResult, options: RenderOptions): string {
  const { redirectLocation, routeError } = result;
  const hasErrors = !!routeError;

  if (hasErrors) {
    console.error(`React Router ERROR: ${JSON.stringify(routeError)}`);
  }

  if (redirectLocation) {
    if (options.trace) {
      const redirectPath = redirectLocation.pathname + redirectLocation.search;
      console.log(`ROUTER REDIRECT: ${options.name} to dom node with id: ${options.domNodeId}, redirect to ${redirectPath}`);
    }
    return '';
  }

  return result.renderedHtml as string;
}

function processPromise(result: Promise<unknown>, renderingReturnsPromises: boolean): Promise<string> | string {
  if (!renderingReturnsPromises) {
    console.error('Your render function returned a Promise, which is only supported by a node renderer, not ExecJS.');
    // If the app is using server rendering with ExecJS, then the promise will not be awaited.
    // And when a promise is passed to JSON.stringify, it will be converted to '{}'.
    return '{}';
  }
  return result as Promise<string>;
}

function processReactElement(result: ReactElement): string {
  try {
    return ReactDOMServer.renderToString(result);
  } catch (error) {
    console.error(`Invalid call to renderToString. Possibly you have a renderFunction, a function that already
calls renderToString, that takes one parameter. You need to add an extra unused parameter to identify this function
as a renderFunction and not a simple React Function Component.`);
    throw error;
  }
}

function processRenderingResult(result: CreateReactOutputResult, options: RenderOptions): string | Promise<string> {
  if (isServerRenderHash(result)) {
    return processServerRenderHash(result, options);
  }
  if (isPromise(result)) {
    return processPromise(result, options.renderingReturnsPromises);
  }
  return processReactElement(result);
}

function handleRenderingError(e: Error, renderState: RenderState, options: { name: string, throwJsErrors: boolean }) {
  if (options.throwJsErrors) {
    throw e;
  }
  return {
    ...renderState,
    hasErrors: true,
    result: handleError({ e, name: options.name, serverSide: true }),
    error: e,
  };
}

function createResultObject(html: string | null, consoleReplayScript: string, hasErrors: boolean, error: RenderingError | null): RenderResult {
  const result: RenderResult = { html, consoleReplayScript, hasErrors };
  if (error) {
    result.renderingError = {
      message: error.message,
      stack: error.stack,
    };
  }
  return result;
}

function createSyncResult(renderState: RenderState & { result: string | null }, consoleReplayScript: string): RenderResult {
  return createResultObject(renderState.result, consoleReplayScript, renderState.hasErrors, renderState.error);
}

function createPromiseResult(renderState: RenderState & { result: Promise<string> }, consoleReplayScript: string): Promise<RenderResult> {
  return (async () => {
    try {
      const html = await renderState.result;
      return createResultObject(html, consoleReplayScript, renderState.hasErrors, renderState.error);
    } catch (e: unknown) {
      const error = e instanceof Error ? e : new Error(String(e));
      const html = handleError({ e: error, name: 'Unknown', serverSide: true });
      return createResultObject(html, consoleReplayScript, true, error);
    }
  })();
}

function createFinalResult(renderState: RenderState): null | string | Promise<RenderResult> {
  const consoleReplayScript = buildConsoleReplay();

  const { result } = renderState;
  if (isPromise(result)) {
    return createPromiseResult({ ...renderState, result }, consoleReplayScript);
  }

  return JSON.stringify(createSyncResult({ ...renderState, result }, consoleReplayScript));
}

function serverRenderReactComponentInternal(options: RenderParams): null | string | Promise<RenderResult> {
  const { name, domNodeId, trace, props, railsContext, renderingReturnsPromises, throwJsErrors } = options;

  let renderState: RenderState = {
    result: null,
    hasErrors: false,
    error: null,
  };

  try {
    const componentObj = ComponentRegistry.get(name);
    validateComponent(componentObj, name);

    // Renders the component or executes the render function
    // - If the registered component is a React element or component, it renders it
    // - If it's a render function, it executes the function and processes the result:
    //   - For React elements or components, it renders them
    //   - For promises, it returns them without awaiting (for async rendering)
    //   - For other values (e.g., strings), it returns them directly
    // Note: Only synchronous operations are performed at this stage
    const reactRenderingResult = createReactOutput({ componentObj, domNodeId, trace, props, railsContext });
    // Processes the result from createReactOutput:
    // 1. Converts React elements to HTML strings
    // 2. Returns rendered HTML from serverRenderHash
    // 3. Handles promises for async rendering
    renderState.result = processRenderingResult(reactRenderingResult, { name, domNodeId, trace, renderingReturnsPromises });
  } catch (e) {
    renderState = handleRenderingError(e as Error, renderState, { name, throwJsErrors });
  }

  // Finalize the rendering result and prepare it for server response
  // 1. Builds the consoleReplayScript for client-side console replay
  // 2. Handles both synchronous and asynchronous (Promise) results
  // 3. Constructs a JSON object with the following properties:
  //    - html: string | null (The rendered component HTML)
  //    - consoleReplayScript: string (Script to replay console outputs on the client)
  //    - hasErrors: boolean (Indicates if any errors occurred during rendering)
  //    - renderingError: Error | null (The error object if an error occurred, null otherwise)
  // 4. For Promise results, it awaits resolution before creating the final JSON
  return createFinalResult(renderState);
}

const serverRenderReactComponent: typeof serverRenderReactComponentInternal = (options) => {
  try {
    return serverRenderReactComponentInternal(options);
  } finally {
    // Reset console history after each render.
    // See `RubyEmbeddedJavaScript.console_polyfill` for initialization.
    console.history = [];
  }
};

export default serverRenderReactComponent;
