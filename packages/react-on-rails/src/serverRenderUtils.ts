import type {
  RegisteredComponent,
  RenderResult,
  RenderState,
  RenderingError,
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
      stack: renderState.error.stack,
    },
    isShellReady: 'isShellReady' in renderState ? renderState.isShellReady : undefined,
  };
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
  for (let i = 0; i < str.length; i++) {
    const code = str.charCodeAt(i);
    if (code <= 0x7f) {
      bytes += 1;
    } else if (code <= 0x7ff) {
      bytes += 2;
    } else if (code >= 0xd800 && code <= 0xdbff) {
      const next = i + 1 < str.length ? str.charCodeAt(i + 1) : 0;
      if (next >= 0xdc00 && next <= 0xdfff) {
        bytes += 4; // valid surrogate pair
        i++;
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
  // html can be a string (common), null, or a ServerRenderHashRenderedHtml object
  // (when render functions return multiple named HTML fragments like { componentHtml, title }).
  // For object values, JSON-serialize them so the content is a valid string on the wire.
  let htmlStr: string;
  if (html == null) {
    htmlStr = '';
  } else if (typeof html === 'string') {
    htmlStr = html;
  } else {
    htmlStr = JSON.stringify(html);
  }
  const metadata = JSON.stringify(buildRenderMetadata(consoleReplayScript, renderState));
  const byteLength = utf8ByteLength(htmlStr);
  return `${metadata}\t${byteLength.toString(16).padStart(8, '0')}\n${htmlStr}`;
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
