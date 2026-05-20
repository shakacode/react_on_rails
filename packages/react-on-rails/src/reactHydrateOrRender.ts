import type { ReactElement } from 'react';
import type { RenderReturnType } from './types/index.ts';
import type { ReactHydrateOptions } from './reactApis.cts';
import { reactHydrate, reactRender } from './reactApis.cts';

export default function reactHydrateOrRender(
  domNode: Element,
  reactElement: ReactElement,
  hydrate: boolean,
  hydrateOptions?: ReactHydrateOptions,
): RenderReturnType {
  return hydrate ? reactHydrate(domNode, reactElement, hydrateOptions) : reactRender(domNode, reactElement);
}
