'use client';

import * as React from 'react';
import * as ReactDOMClient from 'react-dom/client';
import { RailsContext, RenderFunction } from './types/index.ts';
import { ensureReactUseAvailable } from './reactApis.cts';
import { createRSCProvider } from './RSCProvider.tsx';
import { getReactServerComponent, getPreloadedReactServerComponents } from './getReactServerComponent.client.ts';

ensureReactUseAvailable();

export type RSCClientRootProps = { ServerComponentContainer: ReactComponent };

/**
 * RSCClientRoot is a React component that handles client-side rendering of React Server Components (RSC).
 * It manages the fetching, caching, and rendering of RSC payloads from the server.
 *
 * This component:
 * 1. Fetches RSC payloads from the server using the provided URL path
 * 2. Caches the responses to prevent duplicate requests
 * 3. Transforms the response stream to replay server-side console logs
 * 4. Uses React.use() to handle the async data fetching
 *
 * @requires React 19+
 * @requires react-on-rails-rsc
 */
const RSCClientRoot: RenderFunction = async (
  { ServerComponentContainer }: RSCClientRootProps,
  railsContext?: RailsContext,
  domNodeId?: string,
) => {
  if (!railsContext) {
    throw new Error('RSCClientRoot: No railsContext provided');
  }

  const RSCProvider = await createRSCProvider({
    railsContext,
    getServerComponent: getReactServerComponent,
    getPreloadedComponents: getPreloadedReactServerComponents,
  });

  const SuspensableRSCRoute = (
    <React.Suspense fallback={null}>
      <ServerComponentContainer />
    </React.Suspense>
  );

  const root = <RSCProvider>{SuspensableRSCRoute}</RSCProvider>;

  if (!domNodeId) {
    throw new Error('RSCClientRoot: No domNodeId provided');
  }
  const domNode = document.getElementById(domNodeId);
  if (!domNode) {
    throw new Error(`RSCClientRoot: No DOM node found for id: ${domNodeId}`);
  }
  if (domNode.innerHTML) {
    ReactDOMClient.hydrateRoot(domNode, root);
  } else {
    ReactDOMClient.createRoot(domNode).render(root);
  }
  // Added only to satisfy the return type of RenderFunction
  // However, the returned value of renderFunction is not used in ReactOnRails
  // TODO: fix this behavior
  return '';
};

export default RSCClientRoot;
