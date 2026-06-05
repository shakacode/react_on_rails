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

    // hydrateRoot renders eagerly from its second argument; createRoot needs a later render call.
    const root = shouldHydrate
      ? ReactDOMClient.hydrateRoot(domNode, element)
      : ReactDOMClient.createRoot(domNode);
    reactRoots.set(domNode, root);

    if (!shouldHydrate) {
      root.render(element);
    }
  };
}

// WeakMap entries clear when the DOM Element is collected. A root can stay live briefly if
// navigation teardown detaches later, but this dummy helper does not own that lifecycle.
const domRenderers = { hydrateOrRender };

export default domRenderers;
export { hydrateOrRender };
export type { DomRenderer };
