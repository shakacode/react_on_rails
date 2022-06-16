import { ReactElement, Component } from 'react';
import supportsReactCreateRoot from './supportsReactCreateRoot';

// eslint-disable-next-line import/no-dynamic-require
const ReactDOM = require(`react-dom${supportsReactCreateRoot ? '/client' : ''}`);

export default function reactHydrate(domNode: Element, reactElement: ReactElement): void | Element | Component {
  if (supportsReactCreateRoot) {
    return ReactDOM.hydrateRoot(domNode, reactElement);
  }

  return ReactDOM.hydrate(reactElement, domNode);
}
