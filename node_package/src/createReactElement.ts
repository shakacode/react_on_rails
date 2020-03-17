/* eslint-disable react/prop-types */

import React from 'react';
import type { CreateParams, ComponentVariant, RenderFunction, CREReturnTypes } from './types/index';

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

  if (generatorFunction) {
    return (component as RenderFunction)(props, railsContext);
  }

  return React.createElement(component as ComponentVariant, props);
}
