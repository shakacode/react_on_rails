/*
 * Copyright (c) 2025 Shakacode LLC
 *
 * This file is NOT licensed under the MIT (open source) license.
 * It is part of the React on Rails Pro offering and is licensed separately.
 *
 * Unauthorized copying, modification, distribution, or use of this file,
 * via any medium, is strictly prohibited without a valid license agreement
 * from Shakacode LLC.
 *
 * For licensing terms, please see:
 * https://github.com/shakacode/react_on_rails/blob/master/REACT-ON-RAILS-PRO-LICENSE.md
 */

// Side-effect import: keeps `react-on-rails-rsc/client.browser` in the webpack
// module graph for the client bundle so RSCWebpackPlugin (which scans every
// parsed module for this exact resource) can detect the client runtime and
// emit `react-client-manifest.json`. Without this direct import, the plugin
// relies on a 3-level transitive chain
// (`wrapServerComponentRenderer/client` → `getReactServerComponent.client`
// → `react-on-rails-rsc/client.browser`). Any tooling that severs that chain
// (tree-shaking, transpilers, NormalModuleReplacement, custom externals)
// silently drops the manifest and breaks RSC hydration on the renderer.
import 'react-on-rails-rsc/client.browser';
import * as React from 'react';
import * as ReactDOMClient from 'react-dom/client';
import { ReactComponentOrRenderFunction, RenderFunction } from 'react-on-rails/types';
import isRenderFunction from 'react-on-rails/isRenderFunction';
import { ensureReactUseAvailable } from 'react-on-rails/reactApis';
import { createRSCProvider } from '../RSCProvider.tsx';
import getReactServerComponent from '../getReactServerComponent.client.ts';
import { isRSCRouteSSRFalseBailoutError } from '../RSCRouteSSRFalseBailoutError.ts';

ensureReactUseAvailable();

/**
 * Wraps a client component with the necessary RSC context and handling for client-side operations.
 *
 * This higher-order function:
 * 1. Creates an RSCProvider with client-specific implementation of getReactServerComponent
 * 2. Handles DOM hydration or rendering operations
 * 3. Ensures Suspense boundaries are properly set up for async rendering
 *
 * Use this version specifically for client bundle registration.
 *
 * @param componentOrRenderFunction - Client component or render function to wrap
 * @returns A render function that handles client-side RSC operations and DOM hydration that should be registered with ReactOnRails.register
 *
 * @example
 * ```tsx
 * const WrappedComponent = WrapServerComponentRenderer(ClientComponent);
 * ReactOnRails.register({ ClientComponent: WrappedComponent });
 * ```
 */
const wrapServerComponentRenderer = (
  componentOrRenderFunction: ReactComponentOrRenderFunction,
  componentName: string = 'Unknown',
) => {
  if (typeof componentOrRenderFunction !== 'function') {
    throw new Error(`wrapServerComponentRenderer: component '${componentName}' is not a function`);
  }

  const wrapper: RenderFunction = async (props, railsContext, domNodeId) => {
    const Component = isRenderFunction(componentOrRenderFunction)
      ? await componentOrRenderFunction(props, railsContext, domNodeId)
      : componentOrRenderFunction;

    if (typeof Component !== 'function') {
      throw new Error(`wrapServerComponentRenderer: component '${componentName}' is not a function`);
    }

    if (!domNodeId) {
      throw new Error(`RSCClientRoot: No domNodeId provided for server component '${componentName}'`);
    }
    const domNode = document.getElementById(domNodeId);
    if (!domNode) {
      throw new Error(
        `RSCClientRoot: No DOM node found for id: ${domNodeId} (server component '${componentName}')`,
      );
    }

    if (!railsContext) {
      throw new Error(
        `RSCClientRoot: No railsContext provided for server component '${componentName}'.\n` +
          `This usually means an incompatible version of react_on_rails or react_on_rails_pro.`,
      );
    }

    const RSCProvider = createRSCProvider({
      getServerComponent: getReactServerComponent(domNodeId, railsContext),
    });

    const root = (
      <RSCProvider>
        <React.Suspense fallback={null}>
          <Component {...props} />
        </React.Suspense>
      </RSCProvider>
    );

    if (domNode.innerHTML) {
      ReactDOMClient.hydrateRoot(domNode, root, {
        identifierPrefix: domNodeId,
        onRecoverableError(error) {
          const cause =
            error instanceof Error && 'cause' in error
              ? (error as Error & { cause?: unknown }).cause
              : undefined;

          if (isRSCRouteSSRFalseBailoutError(error) || isRSCRouteSSRFalseBailoutError(cause)) {
            return;
          }

          if (typeof globalThis.reportError === 'function') {
            globalThis.reportError(error);
          } else {
            console.error(error);
          }
        },
      });
    } else {
      ReactDOMClient.createRoot(domNode, { identifierPrefix: domNodeId }).render(root);
    }
    // Added only to satisfy the return type of RenderFunction
    // However, the returned value of renderFunction is not used in ReactOnRails
    // TODO: fix this behavior
    return '';
  };

  return wrapper;
};

export default wrapServerComponentRenderer;
