/* eslint-disable react/prop-types */

import React from 'react';
import type { ServerRenderResult,
  CreateParams, ReactComponentVariant, GeneratorFunction, CreateReactOutputResult } from './types/index';
import isServerRenderResult from "./isServerRenderResult";

/**
 * Logic to either call the generatorFunction or call React.createElement to get the
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
  const { name, component, generatorFunction } = componentObj;

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

  if (generatorFunction) {
    // Let's invoke the function to get the result
    let result = (component as GeneratorFunction)(props, railsContext);
    if (isServerRenderResult(result as CreateReactOutputResult)) {
      // We just return at this point, because calling function knows how to handle this case and
      // we can't call React.createElement with this type of Object.
      return (result as ServerRenderResult);
    } else { // else we'll be calling React.createElement
      let reactComponent = result as ReactComponentVariant;
      return React.createElement(reactComponent, props);
    }
  } else {
    return React.createElement(component as ReactComponentVariant, props);
  }

}
