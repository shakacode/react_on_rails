import type { ReactElement } from 'react';
import type { RenderReturnType } from './types/index.ts';
import { reactHydrate, reactRender } from './reactApis.cts';

export default function reactHydrateOrRender(
  domNode: Element,
  reactElement: ReactElement,
  hydrate: boolean,
): RenderReturnType {
  return hydrate ? reactHydrate(domNode, reactElement) : reactRender(domNode, reactElement);
}
