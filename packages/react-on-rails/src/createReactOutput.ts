import { createElement, isValidElement, type ReactElement } from 'react';
import type {
  CreateParams,
  ReactComponent,
  ServerRenderFunction,
  CreateReactOutputResult,
} from './types/index.ts';
import { isServerRenderHash, isPromise } from './isServerRenderResult.ts';
import { isRendererTeardownResult } from './rendererTeardown.ts';

const unsupportedManualRendererMessage = (name: string) =>
  `ReactOnRails.render() does not support renderer functions ("${name}"). ` +
  'Use normal React on Rails component rendering so renderer teardowns are captured on navigation.';

function isReactObjectComponentType(value: unknown): value is ReactComponent {
  if (value == null || typeof value !== 'object') {
    return false;
  }

  // React.memo, React.forwardRef, React.lazy, and related component types are non-callable
  // objects tagged with React's element-type marker.
  const typeMarker = (value as { $$typeof?: unknown }).$$typeof;
  return typeof typeMarker === 'symbol' || typeof typeMarker === 'number';
}

function isReactComponentType(value: unknown): value is ReactComponent {
  return typeof value === 'function' || typeof value === 'string' || isReactObjectComponentType(value);
}

function createReactElementFromRenderFunctionResult(
  renderFunctionResult: ReactComponent,
  name: string,
  props: Record<string, unknown> | undefined,
): ReactElement {
  if (isValidElement(renderFunctionResult)) {
    // If already a ReactElement, then just return it.
    console.error(
      `Warning: ReactOnRails: Your registered render-function (ReactOnRails.register) for ${name}
incorrectly returned a React Element (JSX). Instead, return a React Function Component by
wrapping your JSX in a function. ReactOnRails v13 will throw error on this, as React Hooks do not
work if you return JSX. Update by wrapping the result JSX of ${name} in a fat arrow function.`,
    );
    return renderFunctionResult;
  }

  // If a component, then wrap in an element
  return createElement(renderFunctionResult, props);
}

/**
 * Logic to either call the renderFunction or call React.createElement to get the
 * React.Component
 * @param options
 * @param options.componentObj
 * @param options.props
 * @param options.domNodeId
 * @param options.trace
 * @param options.location
 * @returns {ReactElement}
 */
export default function createReactOutput({
  componentObj,
  props,
  railsContext,
  domNodeId,
  trace,
  shouldHydrate,
}: CreateParams): CreateReactOutputResult {
  const { name, component, renderFunction, isRenderer } = componentObj;

  if (trace) {
    if (railsContext && railsContext.serverSide) {
      console.log(`RENDERED ${name} to dom node with id: ${domNodeId}`);
    } else if (shouldHydrate) {
      console.log(
        `HYDRATED ${name} in dom node with id: ${domNodeId} using props, railsContext:`,
        props,
        railsContext,
      );
    } else {
      console.log(
        `RENDERED ${name} to dom node with id: ${domNodeId} with props, railsContext:`,
        props,
        railsContext,
      );
    }
  }

  if (renderFunction) {
    // Let's invoke the function to get the result
    if (trace) {
      console.log(`${name} is a renderFunction`);
    }
    // createReactOutput only handles render-functions that return a component or server-render hash.
    // The 3-argument renderer form (which owns its own mount and may return a RendererTeardownResult)
    // never reaches here on the supported paths: the client renderers delegate it earlier
    // (`delegateToRenderer`) and return before this call, and server rendering rejects it upstream in
    // validateComponent ("Detected a renderer while server rendering"). The only path that reaches
    // here with a renderer is the manual public `ReactOnRails.render()` API, where renderers are
    // unsupported because their teardown can't be tracked for cleanup. Reject it loudly and *before*
    // invoking, rather than calling it with no domNodeId and rendering a half-wired, leak-prone result.
    if (isRenderer) {
      throw new Error(unsupportedManualRendererMessage(name));
    }

    if (typeof component !== 'function') {
      throw new Error(`Registered render function "${name}" must be a function.`);
    }

    // The cast only narrows the broad RegisteredComponentValue union (which isn't structurally
    // callable) to a concrete render-function role; it does not widen what may be returned.
    const renderFunctionResult = (component as ServerRenderFunction)(props, railsContext);
    // Defense-in-depth: RenderFunction (= ServerRenderFunction) returns RenderFunctionResult, which
    // already excludes RendererTeardownResult at the type level, so a teardown can't arrive here from
    // a typed caller. Reject it at runtime anyway for untyped JS callers that ignore the contract.
    if (isRendererTeardownResult(renderFunctionResult)) {
      throw new Error(unsupportedManualRendererMessage(name));
    }

    if (isServerRenderHash(renderFunctionResult)) {
      // We just return at this point, because calling function knows how to handle this case and
      // we can't call React.createElement with this type of Object.
      return renderFunctionResult;
    }

    if (isPromise(renderFunctionResult)) {
      // We just return at this point, because calling function knows how to handle this case and
      // we can't call React.createElement with this type of Object.
      return renderFunctionResult.then((result) => {
        if (isRendererTeardownResult(result)) {
          throw new Error(unsupportedManualRendererMessage(name));
        }
        // If the result is a function, then it returned a React Component (even class components are functions).
        if (typeof result === 'function') {
          return createReactElementFromRenderFunctionResult(result, name, props);
        }
        return result;
      });
    }

    return createReactElementFromRenderFunctionResult(renderFunctionResult, name, props);
  }

  if (!isReactComponentType(component)) {
    throw new Error(
      `Registered component "${name}" must be a function, string, or React object component type.`,
    );
  }

  return createElement(component, props);
}
