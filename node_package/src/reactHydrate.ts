import ReactDOM from 'react-dom';
import { ReactElement, Component } from 'react';

export default function reactHydrate(domNode: Element, reactElement: ReactElement): void | Element | Component {
  // @ts-expect-error potentially present if React 18 or greater
  if (ReactDOM.hydrateRoot) {
    // @ts-expect-error potentially present if React 18 or greater
    return ReactDOM.hydrateRoot(domNode, reactElement);
  }

  return ReactDOM.hydrate(reactElement, domNode);
}
