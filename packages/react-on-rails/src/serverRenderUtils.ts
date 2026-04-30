import type {
  RegisteredComponent,
  RenderResult,
  RenderState,
  StreamRenderState,
  FinalHtmlResult,
} from './types/index.ts';

export function createResultObject(
  html: FinalHtmlResult | null,
  consoleReplayScript: string,
  renderState: RenderState | StreamRenderState,
): RenderResult {
  return {
    html,
    clientProps: renderState.clientProps,
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
  if (e instanceof Error) {
    return e;
  }

  const ErrorWithCause = Error as new (message?: string, options?: { cause?: unknown }) => Error;
  return new ErrorWithCause(String(e), { cause: e });
}

export function validateComponent(componentObj: RegisteredComponent, componentName: string) {
  if (componentObj.isRenderer) {
    throw new Error(
      `Detected a renderer while server rendering component '${componentName}'. See https://github.com/shakacode/react_on_rails#renderer-functions`,
    );
  }
}
