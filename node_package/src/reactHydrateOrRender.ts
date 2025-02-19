import type { ReactElement } from 'react';
import ReactDomClient from 'react-dom/client';
import type { RenderReturnType } from './types/index.js';

type HydrateOrRenderType = (domNode: Element, reactElement: ReactElement) => RenderReturnType;

const reactHydrate: HydrateOrRenderType = ReactDomClient.hydrateRoot;

function reactRender(domNode: Element, reactElement: ReactElement): RenderReturnType {
  const root = ReactDomClient.createRoot(domNode);
  root.render(reactElement);
  return root;
}

export default function reactHydrateOrRender(domNode: Element, reactElement: ReactElement, hydrate: boolean): RenderReturnType {
  return hydrate ? reactHydrate(domNode, reactElement) : reactRender(domNode, reactElement);
}
