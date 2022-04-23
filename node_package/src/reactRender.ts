import { ReactElement, Component } from 'react';
import supportsReactCreateRoot from './supportsReactCreateRoot';

// eslint-disable-next-line import/no-unresolved
const ReactDOM = supportsReactCreateRoot ? require("react-dom/client") : require("react-dom");

export default function reactRender(domNode: Element, reactElement: ReactElement): void | Element | Component {
  if (supportsReactCreateRoot) {
    const root = ReactDOM.createRoot(domNode);
    root.render(reactElement);
    return root
  }

  // eslint-disable-next-line react/no-render-return-value
  return ReactDOM.render(reactElement, domNode);
}
