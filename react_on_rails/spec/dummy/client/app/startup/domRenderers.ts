import type { ReactNode } from 'react';
import ReactDOMClient from 'react-dom/client';

type ReactRoot = ReturnType<typeof ReactDOMClient.createRoot>;

const reactRoots = new WeakMap<Element, ReactRoot>();

type DomRenderer = (domNode: Element, element: ReactNode) => void;

function hydrateOrRender(shouldHydrate: boolean): DomRenderer {
  return (domNode, element) => {
    const existingRoot = reactRoots.get(domNode);
    if (existingRoot) {
      existingRoot.render(element);
      return;
    }

    const root = shouldHydrate
      ? ReactDOMClient.hydrateRoot(domNode, element)
      : ReactDOMClient.createRoot(domNode);
    reactRoots.set(domNode, root);

    if (!shouldHydrate) {
      root.render(element);
    }
  };
}

export { hydrateOrRender };
export type { DomRenderer };
