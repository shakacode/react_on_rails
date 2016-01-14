import React from 'react';
import ReactOnRails from './ReactOnRails';

/**
 * Logic to either call the generatorFunction or call React.createElement to get the
 * React.Component
 * @param options
 * @param options.name
 * @param options.props
 * @param options.domNodeId
 * @param options.trace
 * @param options.location
 * @returns {Element}
 */
export default function createReactElement({
  name,
  props,
  domNodeId,
  trace,
  location,
  }) {
  if (trace) {
    console.log('RENDERED ' + name + ' to dom node with id: ' + domNodeId);
  }

  const componentObj = ReactOnRails.getComponent(name);

  // CONSIDER NOT RELEASING THE OPTION version
  const { component, generatorFunction } = componentObj;

  if (generatorFunction) {
    return component(props, location);
  }

  return React.createElement(component, props);
}
