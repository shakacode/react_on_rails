/* Copyright (c) 2015–2025 ShakaCode, LLC
   SPDX-License-Identifier: MIT */

import handleError from './handleError.ts';
import serverRenderReactComponent from './serverRenderReactComponent.ts';
import type { RenderParams, RenderResult, ErrorOptions } from './types/index.ts';

import Client from './ReactOnRails.client.ts';

if (typeof window !== 'undefined') {
  // warn to include a collapsed stack trace
  console.warn(
    'Optimization opportunity: "react-on-rails" includes ~14KB of server-rendering code. Browsers may not need it. See https://forum.shakacode.com/t/how-to-use-different-versions-of-a-file-for-client-and-server-rendering/1352 (Requires creating a free account). Click this for the stack trace.',
  );
}

Client.handleError = (options: ErrorOptions): string | undefined => handleError(options);

Client.serverRenderReactComponent = (options: RenderParams): null | string | Promise<RenderResult> =>
  serverRenderReactComponent(options);

export * from './types/index.ts';
export default Client;
