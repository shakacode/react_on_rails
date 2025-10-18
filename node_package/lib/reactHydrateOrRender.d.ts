import type { ReactElement } from 'react';
import type { RenderReturnType } from './types/index.ts';

export default function reactHydrateOrRender(
  domNode: Element,
  reactElement: ReactElement,
  hydrate: boolean,
): RenderReturnType;
