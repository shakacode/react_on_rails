import React from 'react';
import ReactOnRails from './ReactOnRails';

export default function createReactElement(
  { componentName,
    props,
    domId,
    trace,
    generatorFunction: domGeneratorFunction,
    location }) {
  console.log('ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ');
  console.log('domGeneratorFunction is', domGeneratorFunction);
  console.log('ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ');

  if (trace) {
    console.log('RENDERED ' + componentName + ' to dom node with id: ' + domId);
  }

  const componentObj = ReactOnRails.getComponent(componentName);
  const { component, generatorFunction } = componentObj;
  if (generatorFunction) {
    return component(props, location);
  }

  return React.createElement(component, props);
}
