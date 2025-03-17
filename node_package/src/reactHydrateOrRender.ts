import type { ReactElement } from 'react';
import * as ReactDOM from 'react-dom';
import type { RenderReturnType } from './types';
import { supportsRootApi } from './reactApis';

type HydrateOrRenderType = (domNode: Element, reactElement: ReactElement) => RenderReturnType;

// TODO: once React dependency is updated to >= 18, we can remove this and just
// import ReactDOM from 'react-dom/client';
let reactDomClient: typeof import('react-dom/client');
if (supportsRootApi) {
  // This will never throw an exception, but it's the way to tell Webpack the dependency is optional
  // https://github.com/webpack/webpack/issues/339#issuecomment-47739112
  // Unfortunately, it only converts the error to a warning.
  try {
    // eslint-disable-next-line global-require,@typescript-eslint/no-require-imports
    reactDomClient = require('react-dom/client') as typeof import('react-dom/client');
  } catch (_e) {
    // We should never get here, but if we do, we'll just use the default ReactDOM
    // and live with the warning.
    reactDomClient = ReactDOM as unknown as typeof import('react-dom/client');
  }
}

/* eslint-disable react/no-deprecated,@typescript-eslint/no-deprecated,@typescript-eslint/no-non-null-assertion --
 * while we need to support React 16
 */
const reactHydrate: HydrateOrRenderType = supportsRootApi
  ? reactDomClient!.hydrateRoot
  : (domNode, reactElement) => ReactDOM.hydrate(reactElement, domNode);

function reactRender(domNode: Element, reactElement: ReactElement): RenderReturnType {
  if (supportsRootApi) {
    const root = reactDomClient!.createRoot(domNode);
    root.render(reactElement);
    return root;
  }

  // eslint-disable-next-line react/no-render-return-value
  return ReactDOM.render(reactElement, domNode);
}
/* eslint-enable react/no-deprecated,@typescript-eslint/no-deprecated,@typescript-eslint/no-non-null-assertion */

export default function reactHydrateOrRender(
  domNode: Element,
  reactElement: ReactElement,
  hydrate: boolean,
): RenderReturnType {
  return hydrate ? reactHydrate(domNode, reactElement) : reactRender(domNode, reactElement);
}
