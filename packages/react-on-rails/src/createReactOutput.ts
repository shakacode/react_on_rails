import { createElement, isValidElement, type ReactElement } from 'react';
import type { CreateParams, ReactComponent, RenderFunction, CreateReactOutputResult } from './types/index.ts';
import { isServerRenderHash, isPromise } from './isServerRenderResult.ts';

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
  const { name, component, renderFunction } = componentObj;

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
    const renderFunctionResult = (component as RenderFunction)(props, railsContext);
    if (isServerRenderHash(renderFunctionResult)) {
      // We just return at this point, because calling function knows how to handle this case and
      // we can't call React.createElement with this type of Object.
      return renderFunctionResult;
    }

    if (isPromise(renderFunctionResult)) {
      // We just return at this point, because calling function knows how to handle this case and
      // we can't call React.createElement with this type of Object.
      return renderFunctionResult.then((result) => {
        // If the result is a function, then it returned a React Component (even class components are functions).
        if (typeof result === 'function') {
          return createReactElementFromRenderFunctionResult(result, name, props);
        }
        return result;
      });
    }

    return createReactElementFromRenderFunctionResult(renderFunctionResult, name, props);
  }
  // else
  return createElement(component as ReactComponent, props);
}
