/* eslint-disable react/prop-types */

import React from 'react';
import type { CreateParams, ComponentVariant, RenderFunction, CREReturnTypes } from './types/index';
import isRouterResult from "./isCreateReactElementResultNonReactComponent";

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
export default function createReactElement({
  componentObj,
  props,
  railsContext,
  domNodeId,
  trace,
  shouldHydrate,
}: CreateParams): CREReturnTypes {
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

  // TODO: replace any
  let ReactComponent: any;
  if (generatorFunction) {
    // Let's invoke the function to get the result
    ReactComponent = (component as RenderFunction)(props, railsContext);
    if (isRouterResult(ReactComponent)) {
      // We just return at this point, because calling function knows how to handle this case and
      // we can't call React.createElement with this type of Object.
      return ReactComponent;
    } // else we'll be calling React.createElement
  } else {
    ReactComponent = component;
  }

  return React.createElement(ReactComponent as ComponentVariant, props);
}
