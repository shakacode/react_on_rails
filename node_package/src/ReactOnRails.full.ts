import handleError from './handleError.js';
import serverRenderReactComponent from './serverRenderReactComponent.js';
import type {
  RenderParams,
  RenderResult,
  ErrorOptions,
} from './types/index.js';

import Client from './ReactOnRails.client.js';

if (typeof window !== 'undefined') {
  console.log('Optimization opportunity: "react-on-rails" includes ~14KB of server-rendering code. Browsers may not need it. See https://forum.shakacode.com/t/how-to-use-different-versions-of-a-file-for-client-and-server-rendering/1352 (Requires creating a free account)');
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

export * from "./types/index.js";
export default Client;
