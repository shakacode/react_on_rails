import type { ReactElement } from 'react';
import { createRoot, hydrateRoot, Root } from 'react-dom/client';

export default function reactHydrateOrRender(
  domNode: Element,
  reactElement: ReactElement,
  hydrate: boolean,
): Root {
  if (hydrate) {
    return hydrateRoot(domNode, reactElement);
  }

  const root = createRoot(domNode);
  root.render(reactElement);
  return root;
}
