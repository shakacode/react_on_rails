import handleError from './handleError';
import serverRenderReactComponent from './serverRenderReactComponent';
import type {
  RenderParams,
  RenderResult,
  ErrorOptions,
} from './types';

import Client from './ReactOnRails.client';

if (typeof window !== 'undefined') {
  throw new Error('"react-on-rails" is for server-side rendering only. Import "react-on-rails/client".');
}

Client.handleError = (options: ErrorOptions): string | undefined => handleError(options);
Client.serverRenderReactComponent = (options: RenderParams): null | string | Promise<RenderResult> => serverRenderReactComponent(options);

export * from "./types";
export default Client;
