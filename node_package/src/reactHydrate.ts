import { ReactElement, Component } from 'react';
import supportsReactCreateRoot from './supportsReactCreateRoot';

// eslint-disable-next-line import/no-unresolved
const ReactDOM = supportsReactCreateRoot ? require("react-dom/client") : require("react-dom");

export default function reactHydrate(domNode: Element, reactElement: ReactElement): void | Element | Component {
  if (supportsReactCreateRoot) {
    return ReactDOM.hydrateRoot(domNode, reactElement);
  }

  return ReactDOM.hydrate(reactElement, domNode);
}
