/* eslint-disable global-require,@typescript-eslint/no-require-imports */
import * as React from 'react';
import * as ReactDOM from 'react-dom';
import type { ReactElement } from 'react';
import type { RenderReturnType } from './types/index.ts' with { 'resolution-mode': 'import' };

// Type for legacy React DOM APIs (React 16/17) that were removed from @types/react-dom@19
// These are only used at runtime when supportsRootApi is false
interface LegacyReactDOM {
  hydrate(element: ReactElement, container: Element): void;
  render(element: ReactElement, container: Element): RenderReturnType;
  unmountComponentAtNode(container: Element): boolean;
}

const reactMajorVersion = Number(ReactDOM.version?.split('.')[0]) || 16;

// TODO: once we require React 18, we can remove this and inline everything guarded by it.
export const supportsRootApi = reactMajorVersion >= 18;

export const supportsHydrate = supportsRootApi || 'hydrate' in ReactDOM;

// TODO: once React dependency is updated to >= 18, we can remove this and just
// import ReactDOM from 'react-dom/client';
let reactDomClient: typeof import('react-dom/client');
if (supportsRootApi) {
  // This will never throw an exception, but it's the way to tell Webpack the dependency is optional
  // https://github.com/webpack/webpack/issues/339#issuecomment-47739112
  // Unfortunately, it only converts the error to a warning.
  try {
    reactDomClient = require('react-dom/client') as typeof import('react-dom/client');
  } catch (_e) {
    // We should never get here, but if we do, we'll just use the default ReactDOM
    // and live with the warning.
    reactDomClient = ReactDOM as unknown as typeof import('react-dom/client');
  }
}

type HydrateOrRenderType = (domNode: Element, reactElement: ReactElement) => RenderReturnType;

// Cast ReactDOM to include legacy APIs for React 16/17 compatibility
// These methods exist at runtime but are removed from @types/react-dom@19
const legacyReactDOM = ReactDOM as unknown as LegacyReactDOM;

/* eslint-disable @typescript-eslint/no-non-null-assertion -- reactDomClient is always defined when supportsRootApi is true */
export const reactHydrate: HydrateOrRenderType = supportsRootApi
  ? reactDomClient!.hydrateRoot
  : (domNode, reactElement) => legacyReactDOM.hydrate(reactElement, domNode);

export function reactRender(domNode: Element, reactElement: ReactElement): RenderReturnType {
  if (supportsRootApi) {
    const root = reactDomClient!.createRoot(domNode);
    root.render(reactElement);
    return root;
  }

  return legacyReactDOM.render(reactElement, domNode);
}

export const unmountComponentAtNode = supportsRootApi
  ? // not used if we use root API
    () => false
  : (container: Element) => legacyReactDOM.unmountComponentAtNode(container);

export const ensureReactUseAvailable = () => {
  if (!('use' in React) || typeof React.use !== 'function') {
    throw new Error(
      'React.use is not defined. Please ensure you are using React 19 to use server components.',
    );
  }
};
