/* Copyright (c) 2015–2025 ShakaCode, LLC
   SPDX-License-Identifier: MIT */

import * as React from 'react';
import ReactOnRails from '../ReactOnRails.client.ts';
import RSCRoute from '../RSCRoute.tsx';
import { ReactComponentOrRenderFunction } from '../types/index.ts';
import wrapServerComponentRenderer from '../wrapServerComponentRenderer/client.tsx';

/**
 * Registers React Server Components (RSC) with React on Rails.
 * This function wraps server components with RSCClientRoot to handle client-side rendering
 * and hydration of RSC payloads.
 *
 * Important: Components registered with this function are not included in the client bundle.
 * Instead, when the component needs to be rendered:
 * 1. A request is made to `${rscPayloadGenerationUrlPath}/${componentName}`
 * 2. The server returns an RSC payload containing:
 *    - Server component rendered output
 *    - References to client components that need hydration
 *    - Data props passed to client components
 * 3. The RSC payload is processed and rendered as HTML on the client
 *
 * This approach enables:
 * - Smaller client bundles (server components code stays on server)
 * - Progressive loading of components
 * - Automatic handling of data requirements
 *
 * @param options - Configuration options for RSC rendering
 * @param options.rscPayloadGenerationUrlPath - The base URL path where RSC payloads will be fetched from
 * @param componentNames - Names of server components to register
 *
 * @example
 * ```js
 * registerServerComponent('ServerComponent1', 'ServerComponent2');
 *
 * // When ServerComponent1 renders, it will fetch from: /rsc_payload/ServerComponent1
 * ```
 */
const registerServerComponent = (...componentNames: string[]) => {
  const componentsWrappedInRSCRoute: Record<string, ReactComponentOrRenderFunction> = {};
  for (const name of componentNames) {
    componentsWrappedInRSCRoute[name] = wrapServerComponentRenderer((props: unknown) => (
      <RSCRoute componentName={name} componentProps={props} />
    ));
  }
  ReactOnRails.register(componentsWrappedInRSCRoute);
};

export default registerServerComponent;
