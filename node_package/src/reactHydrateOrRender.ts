import type { ReactElement } from 'react';
import ReactDOM from 'react-dom';
import type { RenderReturnType } from './types';

type HydrateOrRenderType = (domNode: Element, reactElement: ReactElement) => RenderReturnType;
const supportsReactCreateRoot = ReactDOM.version &&
  parseInt(ReactDOM.version.split('.')[0], 10) >= 18;

// TODO: once React dependency is updated to >= 18, we can remove this and just
// import ReactDOM from 'react-dom/client';
// eslint-disable-next-line @typescript-eslint/no-explicit-any
let reactDomClient: any;
if (supportsReactCreateRoot) {
  // This will never throw an exception, but it's the way to tell Webpack the dependency is optional
  // https://github.com/webpack/webpack/issues/339#issuecomment-47739112
  // Unfortunately, it only converts the error to a warning.
  try {
    // eslint-disable-next-line global-require,import/no-unresolved
    reactDomClient = require('react-dom/client');
  } catch (e) {
    // We should never get here, but if we do, we'll just use the default ReactDOM
    // and live with the warning.
    reactDomClient = ReactDOM;
  }
}

export const reactHydrate: HydrateOrRenderType = supportsReactCreateRoot ?
  reactDomClient.hydrateRoot :
  (domNode, reactElement) => ReactDOM.hydrate(reactElement, domNode);

export function reactRender(domNode: Element, reactElement: ReactElement): RenderReturnType {
  if (supportsReactCreateRoot) {
    const root = reactDomClient.createRoot(domNode);
    root.render(reactElement);
    return root;
  }

  // eslint-disable-next-line react/no-render-return-value
  return ReactDOM.render(reactElement, domNode);
}

export default function reactHydrateOrRender(domNode: Element, reactElement: ReactElement, hydrate: boolean): RenderReturnType {
  return hydrate ? reactHydrate(domNode, reactElement) : reactRender(domNode, reactElement);
}
