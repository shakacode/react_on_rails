import type {
  RegisteredComponent,
  RenderResult,
  RenderState,
  StreamRenderState,
  FinalHtmlResult,
} from './types/index.ts';
export declare function createResultObject(
  html: FinalHtmlResult | null,
  consoleReplayScript: string,
  renderState: RenderState | StreamRenderState,
): RenderResult;
export declare function convertToError(e: unknown): Error;
export declare function validateComponent(componentObj: RegisteredComponent, componentName: string): void;
//# sourceMappingURL=serverRenderUtils.d.ts.map
