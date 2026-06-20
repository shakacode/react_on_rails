import type { RenderingError } from './types/index.ts';

// Must match SOURCE_MAP_STACK_REMAPPER_CONTEXT_KEY in
// packages/react-on-rails-pro-node-renderer/src/worker/vmSourceMapSupport.ts.
const SOURCE_MAPPED_STACK_REMAPPER_KEY = '__reactOnRailsProRemapStackTrace';

type SourceMappedStackRemapper = (stack: unknown) => string | undefined;

type GlobalWithSourceMappedStackRemapper = typeof globalThis & {
  [SOURCE_MAPPED_STACK_REMAPPER_KEY]?: SourceMappedStackRemapper;
};

export function remapSourceMappedStack(stack: RenderingError['stack']) {
  const remapper = (globalThis as GlobalWithSourceMappedStackRemapper)[SOURCE_MAPPED_STACK_REMAPPER_KEY];
  if (typeof remapper !== 'function') {
    return stack;
  }

  try {
    const remappedStack = remapper(stack);
    return typeof remappedStack === 'string' ? remappedStack : stack;
  } catch {
    return stack;
  }
}

function isCrossRealmError(e: unknown): e is { message?: unknown; stack?: unknown } {
  return typeof e === 'object' && e !== null && Object.prototype.toString.call(e) === '[object Error]';
}

function stringifyThrownValue(e: unknown): string {
  if (isCrossRealmError(e)) {
    return typeof e.message === 'string' ? e.message : Object.prototype.toString.call(e);
  }

  if (typeof e === 'object' && e !== null) {
    try {
      // JSON.stringify can return undefined without throwing, for example when toJSON returns undefined.
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
  // tsconfig uses es2020 libs, which do not type Error.cause even though supported runtimes provide it.
  const error = new Error(message) as Error & { cause?: unknown };
  error.cause = e;
  if (isCrossRealmError(e) && typeof e.stack === 'string') {
    // Prefer the cross-realm bundle stack over the host wrapping call site; the
    // original thrown value remains available through `cause`.
    error.stack = remapSourceMappedStack(e.stack);
  }
  return error;
}
