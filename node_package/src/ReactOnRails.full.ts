import handleError from './handleError.ts';
import serverRenderReactComponent from './serverRenderReactComponent.ts';
import type { RenderParams, RenderResult, ErrorOptions } from './types/index.ts';

import Client from './ReactOnRails.client.ts';

if (typeof window !== 'undefined') {
  console.log(
    'Optimization opportunity: "react-on-rails" includes ~14KB of server-rendering code. Browsers may not need it. See https://forum.shakacode.com/t/how-to-use-different-versions-of-a-file-for-client-and-server-rendering/1352 (Requires creating a free account)',
  );
}

Client.handleError = (options: ErrorOptions): string | undefined => handleError(options);

Client.serverRenderReactComponent = (options: RenderParams): null | string | Promise<RenderResult> =>
  serverRenderReactComponent(options);

export * from './types/index.ts';
export default Client;
