/* eslint-disable import/prefer-default-export -- named export for consistency with capability API */

import type { RenderParams, RenderResult, ErrorOptions } from '../types/index.ts';
import handleError from '../handleError.ts';
import serverRenderReactComponent from '../serverRenderReactComponent.ts';

// Warn about bundle size when included in browser bundles
if (typeof window !== 'undefined') {
  console.warn(
    'Optimization opportunity: "react-on-rails" includes ~14KB of server-rendering code. ' +
      'Browsers may not need it. See https://forum.shakacode.com/t/how-to-use-different-versions-of-a-file-for-client-and-server-rendering/1352 ' +
      '(Requires creating a free account). Click this for the stack trace.',
  );
}

/**
 * SSR capability.
 * Provides server-side rendering methods (serverRenderReactComponent, handleError).
 */
export function createSSRCapability() {
  return {
    handleError(options: ErrorOptions): string | undefined {
      return handleError(options);
    },

    serverRenderReactComponent(options: RenderParams): null | string | Promise<RenderResult> {
      return serverRenderReactComponent(options);
    },
  };
}
