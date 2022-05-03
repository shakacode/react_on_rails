import { ReactElement, Component } from 'react';
import supportsReactCreateRoot from './supportsReactCreateRoot';

const reactDomClient = "react-dom/client";
const reactDom = "react-dom";
// eslint-disable-next-line import/no-dynamic-require
const ReactDOM = require(supportsReactCreateRoot ? reactDomClient : reactDom);

export default function reactHydrate(domNode: Element, reactElement: ReactElement): void | Element | Component {
  if (supportsReactCreateRoot) {
    return ReactDOM.hydrateRoot(domNode, reactElement);
  }

  return ReactDOM.hydrate(reactElement, domNode);
}
