/* eslint-disable react/prop-types */

import React from 'react';

/**
 * Logic to either call the generatorFunction or call React.createElement to get the
 * React.Component
 * @param options
 * @param options.componentObj
 * @param options.props
 * @param options.domNodeId
 * @param options.trace
 * @param options.location
 * @returns {Element}
 */
export default function createReactElement({
  componentObj,
  props,
  railsContext,
  domNodeId,
  trace,
  shouldHydrate,
}) {
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
    return component(props, railsContext);
  }

  return React.createElement(component, props);
}
