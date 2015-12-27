import React from 'react';
import ReactOnRails from './ReactOnRails';

export default function createReactElementOrRouterResult(
  { componentName,
    props,
    domId,
    trace,
    generatorFunction,
    location }) {
  if (trace) {
    console.log('RENDERED ' + componentName + ' to dom node with id: ' + domId);
  }

  const component = ReactOnRails.componentForName(componentName);
  if (generatorFunction) {
    return component(props, location);
  }

  return React.createElement(component, props);
}
