import { createBaseClientObject } from './client.ts';
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

export function createBaseFullObject(registries: Parameters<typeof createBaseClientObject>[0]) {
  const clientObject = createBaseClientObject(registries);

  return {
    ...clientObject,

    // Override SSR stubs with real implementations
    handleError(options: ErrorOptions): string | undefined {
      return handleError(options);
    },

    serverRenderReactComponent(options: RenderParams): null | string | Promise<RenderResult> {
      return serverRenderReactComponent(options);
    },
  };
}

export type BaseFullObjectType = ReturnType<typeof createBaseFullObject>;
