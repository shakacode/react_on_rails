/* eslint-disable react/prop-types */

import React from 'react';
import type { ServerRenderResult,
  CreateParams, ReactComponent, RenderFunction, CreateReactOutputResult } from './types/index';
import isServerRenderResult from "./isServerRenderResult";

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
      console.log(`HYDRATED ${name} in dom node with id: ${domNodeId} using props, railsContext:`,
        props, railsContext);
    } else {
      console.log(`RENDERED ${name} to dom node with id: ${domNodeId} with props, railsContext:`,
        props, railsContext);
    }
  }

  if (renderFunction) {
    // Let's invoke the function to get the result
    const renderFunctionResult = (component as RenderFunction)(props, railsContext);
    if (isServerRenderResult(renderFunctionResult as CreateReactOutputResult)) {
      // We just return at this point, because calling function knows how to handle this case and
      // we can't call React.createElement with this type of Object.
      return (renderFunctionResult as ServerRenderResult);
    } // else we'll be calling React.createElement
    // TODO: Can we detect if this is a React Element or a React Function Component?
    // If already a ReactElement, then just return it.
    // If a component, then wrap in an element

    const reactComponent = renderFunctionResult as ReactComponent;

    return React.createElement(reactComponent, props);
  }
  // else
  return React.createElement(component as ReactComponent, props);
}
