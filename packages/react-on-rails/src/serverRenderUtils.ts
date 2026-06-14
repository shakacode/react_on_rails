import type {
  RegisteredComponent,
  RegisteredComponentValue,
  RenderingError,
  FinalHtmlResult,
} from './types/index.ts';

/**
 * Builds the metadata object for the length-prefixed streaming protocol.
 * This is the shared metadata builder used by both streaming and non-streaming paths.
 * It contains everything EXCEPT the html content, which travels as raw bytes.
 */
type RenderMetadataSource = {
  clientProps?: Record<string, unknown>;
  hasErrors?: boolean;
  error?: RenderingError;
  isShellReady?: boolean;
};

const SOURCE_MAPPED_STACK_REMAPPER_KEY = '__reactOnRailsProRemapStackTrace';

type SourceMappedStackRemapper = (stack: unknown) => string | undefined;

type GlobalWithSourceMappedStackRemapper = typeof globalThis & {
  [SOURCE_MAPPED_STACK_REMAPPER_KEY]?: SourceMappedStackRemapper;
};

function remapRenderingErrorStack(stack: RenderingError['stack']) {
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

export function buildRenderMetadata(
  consoleReplayScript: string,
  renderState: RenderMetadataSource,
): Record<string, unknown> {
  return {
    consoleReplayScript,
    clientProps: renderState.clientProps,
    hasErrors: renderState.hasErrors,
    renderingError: renderState.error && {
      message: renderState.error.message,
      stack: remapRenderingErrorStack(renderState.error.stack),
    },
    isShellReady: 'isShellReady' in renderState ? renderState.isShellReady : undefined,
  };
}

function isCrossRealmError(e: unknown): e is { message?: unknown } {
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

/**
 * Returns the UTF-8 byte length of a string.
 * Uses native Buffer.byteLength when available (Node.js, Pro node renderer).
 * Falls back to a pure-JS implementation for environments without Buffer (mini_racer).
 */
function utf8ByteLength(str: string): number {
  if (typeof Buffer !== 'undefined' && typeof Buffer.byteLength === 'function') {
    return Buffer.byteLength(str, 'utf-8');
  }
  let bytes = 0;
  for (let i = 0; i < str.length; i += 1) {
    const code = str.charCodeAt(i);
    if (code <= 0x7f) {
      bytes += 1;
    } else if (code <= 0x7ff) {
      bytes += 2;
    } else if (code >= 0xd800 && code <= 0xdbff) {
      const next = i + 1 < str.length ? str.charCodeAt(i + 1) : 0;
      if (next >= 0xdc00 && next <= 0xdfff) {
        bytes += 4; // valid surrogate pair
        i += 1;
      } else {
        bytes += 3; // lone high surrogate → U+FFFD
      }
    } else {
      bytes += 3; // BMP char (0x800-0xFFFF) or lone low surrogate
    }
  }
  return bytes;
}

/**
 * Builds a length-prefixed result string from html content and render state.
 * Format: <metadata JSON>\t<content byte length hex>\n<raw html content>
 *
 * Used by the non-streaming rendering path. The streaming path uses
 * buildRenderMetadata directly with Buffer operations for efficiency.
 */
export function buildLengthPrefixedResult(
  html: FinalHtmlResult | null,
  consoleReplayScript: string,
  renderState: RenderMetadataSource,
): string {
  // payloadType tells Ruby how to interpret the content bytes:
  //   "string" — raw HTML, use as-is (the common case)
  //   "object" — JSON-serialized value, needs JSON.parse (ServerRenderHash or null)
  const metadataObj = buildRenderMetadata(consoleReplayScript, renderState);
  let htmlStr: string;
  if (typeof html === 'string') {
    metadataObj.payloadType = 'string';
    htmlStr = html;
  } else {
    // Handles null, ServerRenderHashRenderedHtml objects, etc.
    // JSON.stringify(null) → "null", which Ruby will JSON.parse back.
    metadataObj.payloadType = 'object';
    htmlStr = JSON.stringify(html);
  }
  const metadata = JSON.stringify(metadataObj);
  const byteLength = utf8ByteLength(htmlStr);
  return `${metadata}\t${byteLength.toString(16).padStart(8, '0')}\n${htmlStr}`;
}
export function convertToError(e: unknown): Error {
  if (e instanceof Error) {
    return e;
  }

  const message = stringifyThrownValue(e);
  // tsconfig uses es2020 libs, which do not type Error.cause even though supported runtimes provide it.
  const error = new Error(message) as Error & { cause?: unknown };
  error.cause = e;
  return error;
}

export function validateComponent(
  componentObj: RegisteredComponent<RegisteredComponentValue>,
  componentName: string,
) {
  if (componentObj.isRenderer) {
    throw new Error(
      `Detected a renderer while server rendering component '${componentName}'. See https://github.com/shakacode/react_on_rails#renderer-functions`,
    );
  }
}
