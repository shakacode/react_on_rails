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
import {
  ReactComponent,
  ReactComponentOrRenderFunction,
  RendererFunction,
  RendererTeardownResult,
} from 'react-on-rails/types';
import isRenderFunction from 'react-on-rails/isRenderFunction';
import { ensureReactUseAvailable } from 'react-on-rails/reactApis';
import { createRSCProvider } from '../RSCProvider.tsx';
import getReactServerComponent from '../getReactServerComponent.client.ts';
import handleRecoverableError from '../handleRecoverableError.client.ts';

ensureReactUseAvailable();

function isRendererTeardownResult(value: unknown): value is RendererTeardownResult {
  return (
    value != null &&
    typeof value === 'object' &&
    typeof (value as { teardown?: unknown }).teardown === 'function'
  );
}

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

  // The 3-argument arity here is load-bearing: ComponentRegistry classifies a registration as a
  // renderer only when `renderFunction && length === 3`, and only renderers have their returned
  // teardown captured and run on unmount. Dropping `domNodeId` from this signature would silently
  // demote the wrapper to a plain render-function, drop the teardown below, and re-introduce the
  // mount leak this fix closes. Keep all three parameters declared.
  const wrapper: RendererFunction = async (props, railsContext, domNodeId) => {
    // A registerServerComponent render function is expected to resolve to the component to mount,
    // not a renderer teardown. RendererFunction still accepts legacy render-function return shapes
    // because older 3-arg renderers sometimes returned a component just to satisfy the old public
    // type; this wrapper narrows to the expected component shape, and the guard below rejects
    // anything else at runtime.
    const Component = isRenderFunction(componentOrRenderFunction)
      ? ((await componentOrRenderFunction(props, railsContext, domNodeId)) as ReactComponent)
      : componentOrRenderFunction;

    if (isRendererTeardownResult(Component)) {
      throw new Error(
        `wrapServerComponentRenderer: render function for server component '${componentName}' ` +
          'returned a renderer teardown result; expected a React component.',
      );
    }

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

    const rootElement = (
      <RSCProvider>
        <React.Suspense fallback={null}>
          <Component {...props} />
        </React.Suspense>
      </RSCProvider>
    );

    const reactRoot = domNode.innerHTML
      ? ReactDOMClient.hydrateRoot(domNode, rootElement, {
          identifierPrefix: domNodeId,
          onRecoverableError: handleRecoverableError,
        })
      : (() => {
          const root = ReactDOMClient.createRoot(domNode, { identifierPrefix: domNodeId });
          root.render(rootElement);
          return root;
        })();

    // Return an explicit teardown wrapper so React on Rails unmounts this root on Turbo/Turbolinks
    // navigation (the soft-navigation page swap) instead of leaking it. This closes the leak for every
    // registerServerComponent user without confusing legacy bare function returns for cleanup.
    return { teardown: () => reactRoot.unmount() };
  };

  return wrapper;
};

export default wrapServerComponentRenderer;
