/* eslint-disable global-require,@typescript-eslint/no-require-imports */
import type { ReactElement } from 'react';
import type { RenderReturnType } from './_types.ts';
import { supportsRootApi } from './reactApis.cts';

type HydrateOrRenderType = (domNode: Element, reactElement: ReactElement) => RenderReturnType;

// TODO: once React dependency is updated to >= 18, we can remove this and just
// import ReactDOM from 'react-dom/client';
let reactDomClient: typeof import('react-dom/client');
// Can't just import react-dom because that breaks ESM under React 19
let reactDom: typeof import('react-dom');
if (supportsRootApi) {
  // This will never throw an exception, but it's the way to tell Webpack the dependency is optional
  // https://github.com/webpack/webpack/issues/339#issuecomment-47739112
  // Unfortunately, it only converts the error to a warning.
  try {
    reactDomClient = require('react-dom/client') as typeof import('react-dom/client');
  } catch (_e) {
    // We should never get here, but if we do, we'll just use the default ReactDOM
    // and live with the warning.
    reactDomClient = require('react-dom') as unknown as typeof import('react-dom/client');
  }
} else {
  try {
    reactDom = require('react-dom') as typeof import('react-dom');
  } catch (_e) {
    // Also should never happen
  }
}

/* eslint-disable @typescript-eslint/no-deprecated,@typescript-eslint/no-non-null-assertion --
 * while we need to support React 16
 */
const reactHydrate: HydrateOrRenderType = supportsRootApi
  ? reactDomClient!.hydrateRoot
  : (domNode, reactElement) => reactDom!.hydrate(reactElement, domNode);

function reactRender(domNode: Element, reactElement: ReactElement): RenderReturnType {
  if (supportsRootApi) {
    const root = reactDomClient!.createRoot(domNode);
    root.render(reactElement);
    return root;
  }

  return reactDom!.render(reactElement, domNode);
}
/* eslint-enable @typescript-eslint/no-deprecated,@typescript-eslint/no-non-null-assertion */

export default function reactHydrateOrRender(
  domNode: Element,
  reactElement: ReactElement,
  hydrate: boolean,
): RenderReturnType {
  return hydrate ? reactHydrate(domNode, reactElement) : reactRender(domNode, reactElement);
}
