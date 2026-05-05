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

function isCrossRealmError(e: unknown): e is { message?: unknown } {
  return Object.prototype.toString.call(e) === '[object Error]';
}

function stringifyThrownValue(e: unknown): string {
  if (isCrossRealmError(e) && typeof e.message === 'string') {
    return e.message;
  }

  if (typeof e === 'object' && e !== null) {
    try {
      return JSON.stringify(e) ?? Object.prototype.toString.call(e);
    } catch {
      return Object.prototype.toString.call(e);
    }
  }

  return String(e);
}

export function convertToError(e: unknown): Error {
  if (e instanceof Error) {
    return e;
  }

  const message = stringifyThrownValue(e);
  // tsconfig uses es2020 libs, which do not type ErrorOptions even though supported runtimes provide Error.cause.
  const ErrorWithCause = Error as new (message?: string, options?: { cause?: unknown }) => Error;
  return new ErrorWithCause(message, { cause: e });
}

export function validateComponent(componentObj: RegisteredComponent, componentName: string) {
  if (componentObj.isRenderer) {
    throw new Error(
      `Detected a renderer while server rendering component '${componentName}'. See https://github.com/shakacode/react_on_rails#renderer-functions`,
    );
  }
}
