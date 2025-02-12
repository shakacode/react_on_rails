import handleError from './handleError';
import serverRenderReactComponent from './serverRenderReactComponent';
import type {
  RenderParams,
  RenderResult,
  ErrorOptions,
} from './types';

import Client from './ReactOnRails.client';

if (typeof window !== 'undefined') {
  console.log('ReactOnRails: Optimization opportunity: "react-on-rails" includes ~14KB of server-rendering code. Browser may not need it. See https://forum.shakacode.com/t/how-to-use-different-versions-of-a-file-for-client-and-server-rendering/1352 (requires sign in)');
}

/**
 * Used by Rails to catch errors in rendering
 * @param options
 */
Client.handleError = (options: ErrorOptions): string | undefined => handleError(options);

/**
 * Used by server rendering by Rails
 * @param options
 */
Client.serverRenderReactComponent = (options: RenderParams): null | string | Promise<RenderResult> => serverRenderReactComponent(options);

export * from "./types";
export default Client;
