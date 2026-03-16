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

/**
 * Builds the metadata object for the length-prefixed streaming protocol.
 * This is the shared metadata builder used by both streaming and non-streaming paths.
 * It contains everything EXCEPT the html content, which travels as raw bytes.
 */
export function buildRenderMetadata(
  consoleReplayScript: string,
  renderState: RenderState | StreamRenderState,
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
 * Builds a length-prefixed result string from html content and render state.
 * Format: <metadata JSON>\t<content byte length hex>\n<raw html content>
 *
 * Used by the non-streaming rendering path. The streaming path uses
 * buildRenderMetadata directly with Buffer operations for efficiency.
 */
export function buildLengthPrefixedResult(
  html: FinalHtmlResult | null,
  consoleReplayScript: string,
  renderState: RenderState | StreamRenderState,
): string {
  const htmlStr = typeof html === 'string' ? html : '';
  const metadata = JSON.stringify(buildRenderMetadata(consoleReplayScript, renderState));
  const byteLength = Buffer.byteLength(htmlStr, 'utf-8');
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
