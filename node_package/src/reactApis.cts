import * as ReactDOM from 'react-dom';
import type { ReactElement } from 'react';
import type { RenderReturnType } from './types/index.ts' with { 'resolution-mode': 'import' };

const reactMajorVersion = Number(ReactDOM.version?.split('.')[0]) || 16;

// TODO: once we require React 18, we can remove this and inline everything guarded by it.
export const supportsRootApi = reactMajorVersion >= 18;

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

type HydrateOrRenderType = (domNode: Element, reactElement: ReactElement) => RenderReturnType;

/* eslint-disable @typescript-eslint/no-deprecated,@typescript-eslint/no-non-null-assertion --
 * while we need to support React 16
 */
const hydrateProp = 'hydrate';
const renderProp = 'render';

export const reactHydrate: HydrateOrRenderType = supportsRootApi
  ? reactDomClient!.hydrateRoot
  : (domNode, reactElement) => ReactDOM[hydrateProp](reactElement, domNode);

export function reactRender(domNode: Element, reactElement: ReactElement): RenderReturnType {
  if (supportsRootApi) {
    const root = reactDomClient!.createRoot(domNode);
    root.render(reactElement);
    return root;
  }

  return ReactDOM[renderProp](reactElement, domNode);
}
/* eslint-enable @typescript-eslint/no-deprecated,@typescript-eslint/no-non-null-assertion */
