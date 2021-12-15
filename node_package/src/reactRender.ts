import ReactDOM from 'react-dom';
import { ReactElement, Component } from 'react';

export default function reactRender(domNode: Element, reactElement: ReactElement): void | Element | Component {
  // @ts-expect-error potentially present if React 18 or greater
  if (ReactDOM.createRoot) {
    // @ts-expect-error potentially present if React 18 or greater
    const root = ReactDOM.createRoot(domNode);
    root.render(reactElement);
    return root
  }

  // eslint-disable-next-line react/no-render-return-value
  return ReactDOM.render(reactElement, domNode);
}
