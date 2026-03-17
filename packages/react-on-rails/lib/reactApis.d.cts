import type { ReactElement } from 'react';
import type { RenderReturnType } from './types/index.ts' with { 'resolution-mode': 'import' };
export declare const supportsRootApi: boolean;
export declare const supportsHydrate: boolean;
type HydrateOrRenderType = (domNode: Element, reactElement: ReactElement) => RenderReturnType;
export declare const reactHydrate: HydrateOrRenderType;
export declare function reactRender(domNode: Element, reactElement: ReactElement): RenderReturnType;
export declare const unmountComponentAtNode: (container: Element) => boolean;
export declare const ensureReactUseAvailable: () => void;
export {};
//# sourceMappingURL=reactApis.d.cts.map