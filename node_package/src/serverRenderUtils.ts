import type { RegisteredComponent, RenderResult, RenderState, StreamRenderState } from './types/index.ts';

export function createResultObject(
  html: string | null,
  consoleReplayScript: string,
  renderState: RenderState | StreamRenderState,
): RenderResult {
  return {
    html,
    consoleReplayScript,
    hasErrors: renderState.hasErrors,
    renderingError: renderState.error && {
      message: renderState.error.message,
      stack: renderState.error.stack,
    },
    isShellReady: 'isShellReady' in renderState ? renderState.isShellReady : undefined,
  };
}

export function convertToError(e: unknown): Error {
  return e instanceof Error ? e : new Error(String(e));
}

export function validateComponent(componentObj: RegisteredComponent, componentName: string) {
  if (componentObj.isRenderer) {
    throw new Error(
      `Detected a renderer while server rendering component '${componentName}'. See https://github.com/shakacode/react_on_rails#renderer-functions`,
    );
  }
}
