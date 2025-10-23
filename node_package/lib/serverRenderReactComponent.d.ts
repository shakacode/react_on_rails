import type { RenderParams, RenderResult } from './types/index.ts';

declare function serverRenderReactComponentInternal(
  options: RenderParams,
): null | string | Promise<RenderResult>;
declare const serverRenderReactComponent: typeof serverRenderReactComponentInternal;
export default serverRenderReactComponent;
