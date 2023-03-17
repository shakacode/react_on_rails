import type { ReactElement } from 'react';
import type { RenderReturnType } from './types';
type HydrateOrRenderType = (domNode: Element, reactElement: ReactElement) => RenderReturnType;
export declare const reactHydrate: HydrateOrRenderType;
export declare function reactRender(domNode: Element, reactElement: ReactElement): RenderReturnType;
export default function reactHydrateOrRender(domNode: Element, reactElement: ReactElement, hydrate: boolean): RenderReturnType;
export {};
