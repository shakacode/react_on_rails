import ReactDOMServer from 'react-dom/server';
import { PassThrough, Readable } from 'stream';
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
  error?: RenderingError;
};

type RenderOptions = {
  componentName: string;
  domNodeId?: string;
  trace?: boolean;
  renderingReturnsPromises: boolean;
};

function validateComponent(componentObj: RegisteredComponent, componentName: string) {
  if (componentObj.isRenderer) {
    throw new Error(`Detected a renderer while server rendering component '${componentName}'. See https://github.com/shakacode/react_on_rails#renderer-functions`);
  }
}

function processServerRenderHash(result: ServerRenderResult, options: RenderOptions): RenderState {
  const { redirectLocation, routeError } = result;
  const hasErrors = !!routeError;

  if (hasErrors) {
    console.error(`React Router ERROR: ${JSON.stringify(routeError)}`);
  }

  let htmlResult: string;
  if (redirectLocation) {
    if (options.trace) {
      const redirectPath = redirectLocation.pathname + redirectLocation.search;
      console.log(`ROUTER REDIRECT: ${options.componentName} to dom node with id: ${options.domNodeId}, redirect to ${redirectPath}`);
    }
    // For redirects on server rendering, we can't stop Rails from returning the same result.
    // Possibly, someday, we could have the Rails server redirect.
    htmlResult = '';
  } else {
    htmlResult = result.renderedHtml as string;
  }

  return { result: htmlResult, hasErrors };
}

function processPromise(result: Promise<string>, renderingReturnsPromises: boolean): Promise<string> | string {
  if (!renderingReturnsPromises) {
    console.error('Your render function returned a Promise, which is only supported by a node renderer, not ExecJS.');
    // If the app is using server rendering with ExecJS, then the promise will not be awaited.
    // And when a promise is passed to JSON.stringify, it will be converted to '{}'.
    return '{}';
  }
  return result;
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

function processRenderingResult(result: CreateReactOutputResult, options: RenderOptions): RenderState {
  if (isServerRenderHash(result)) {
    return processServerRenderHash(result, options);
  }
  if (isPromise(result)) {
    return { result: processPromise(result, options.renderingReturnsPromises), hasErrors: false };
  }
  return { result: processReactElement(result), hasErrors: false };
}

function handleRenderingError(e: unknown, options: { componentName: string, throwJsErrors: boolean }) {
  if (options.throwJsErrors) {
    throw e;
  }
  const error = e instanceof Error ? e : new Error(String(e));
  return {
    hasErrors: true,
    result: handleError({ e: error, name: options.componentName, serverSide: true }),
    error,
  };
}

function createResultObject(html: string | null, consoleReplayScript: string, renderState: RenderState): RenderResult {
  return {
    html,
    consoleReplayScript,
    hasErrors: renderState.hasErrors,
    renderingError: renderState.error && { message: renderState.error.message, stack: renderState.error.stack },
  };
}

async function createPromiseResult(
  renderState: RenderState & { result: Promise<string> },
  componentName: string,
  throwJsErrors: boolean
): Promise<RenderResult> {
  // Capture console history before awaiting the promise
  // Node renderer will reset the global console.history after executing the synchronous part of the request.
  // It resets it only if replayServerAsyncOperationLogs renderer config is set to false.
  // In both cases, we need to keep a reference to console.history to avoid losing console logs in case of reset.
  const consoleHistory = console.history;
  try {
    const html = await renderState.result;
    const consoleReplayScript = buildConsoleReplay(consoleHistory);
    return createResultObject(html, consoleReplayScript, renderState);
  } catch (e: unknown) {
    const errorRenderState = handleRenderingError(e, { componentName, throwJsErrors });
    const consoleReplayScript = buildConsoleReplay(consoleHistory);
    return createResultObject(errorRenderState.result, consoleReplayScript, renderState);
  }
}

function createFinalResult(
  renderState: RenderState,
  componentName: string,
  throwJsErrors: boolean
): null | string | Promise<RenderResult> {
  const { result } = renderState;
  if (isPromise(result)) {
    return createPromiseResult({ ...renderState, result }, componentName, throwJsErrors);
  }

  const consoleReplayScript = buildConsoleReplay();
  return JSON.stringify(createResultObject(result, consoleReplayScript, renderState));
}

function serverRenderReactComponentInternal(options: RenderParams): null | string | Promise<RenderResult> {
  const { name: componentName, domNodeId, trace, props, railsContext, renderingReturnsPromises, throwJsErrors } = options;

  let renderState: RenderState = {
    result: null,
    hasErrors: false,
  };

  try {
    const componentObj = ComponentRegistry.get(componentName);
    validateComponent(componentObj, componentName);

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
    renderState = processRenderingResult(reactRenderingResult, { componentName, domNodeId, trace, renderingReturnsPromises });
  } catch (e: unknown) {
    renderState = handleRenderingError(e, { componentName, throwJsErrors });
  }

  // Finalize the rendering result and prepare it for server response
  // 1. Builds the consoleReplayScript for client-side console replay
  // 2. Extract the result from promise (if needed) by awaiting it
  // 3. Constructs a JSON object with the following properties:
  //    - html: string | null (The rendered component HTML)
  //    - consoleReplayScript: string (Script to replay console outputs on the client)
  //    - hasErrors: boolean (Indicates if any errors occurred during rendering)
  //    - renderingError: Error | null (The error object if an error occurred, null otherwise)
  // 4. For Promise results, it awaits resolution before creating the final JSON
  return createFinalResult(renderState, componentName, throwJsErrors);
}

const serverRenderReactComponent: typeof serverRenderReactComponentInternal = (options) => {
  try {
    return serverRenderReactComponentInternal(options);
  } finally {
    // Reset console history after each render.
    // See `RubyEmbeddedJavaScript.console_polyfill` for initialization.
    // This is necessary when ExecJS and old versions of node renderer are used.
    // New versions of node renderer reset the console history automatically.
    console.history = [];
  }
};

const stringToStream = (str: string): Readable => {
  const stream = new PassThrough();
  stream.push(str);
  stream.push(null);
  return stream;
};

export const streamServerRenderedReactComponent = (options: RenderParams): Readable => {
  const { name: componentName, domNodeId, trace, props, railsContext, throwJsErrors } = options;

  let renderResult: null | Readable = null;

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

    const renderStream = new PassThrough();
    ReactDOMServer.renderToPipeableStream(reactRenderingResult).pipe(renderStream);
    renderResult = renderStream;

    // TODO: Add console replay script to the stream
    // Ensure to avoid console messages leaking between different components rendering
  } catch (e: any) {
    if (throwJsErrors) {
      throw e;
    }

    renderResult = stringToStream(handleError({
      e,
      name: componentName,
      serverSide: true,
    }));
  }

  return renderResult;
};

export default serverRenderReactComponent;
