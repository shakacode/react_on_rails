import * as React from 'react';
import * as ReactDOMClient from 'react-dom/client';
import { ReactComponentOrRenderFunction, RenderFunction } from '../../types/index.ts';
import isRenderFunction from '../../isRenderFunction.ts';
import { ensureReactUseAvailable } from '../../reactApis.cjs';
import { createRSCProvider } from '../RSCProvider.tsx';
import getReactServerComponent from '../getReactServerComponent.client.ts';

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
const wrapServerComponentRenderer = (componentOrRenderFunction: ReactComponentOrRenderFunction) => {
  if (typeof componentOrRenderFunction !== 'function') {
    throw new Error('wrapServerComponentRenderer: component is not a function');
  }

  const wrapper: RenderFunction = async (props, railsContext, domNodeId) => {
    const Component = isRenderFunction(componentOrRenderFunction)
      ? await componentOrRenderFunction(props, railsContext, domNodeId)
      : componentOrRenderFunction;

    if (typeof Component !== 'function') {
      throw new Error('wrapServerComponentRenderer: component is not a function');
    }

    if (!domNodeId) {
      throw new Error('RSCClientRoot: No domNodeId provided');
    }
    const domNode = document.getElementById(domNodeId);
    if (!domNode) {
      throw new Error(`RSCClientRoot: No DOM node found for id: ${domNodeId}`);
    }

    if (!railsContext) {
      throw new Error('RSCClientRoot: No railsContext provided');
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
      ReactDOMClient.hydrateRoot(domNode, root, { identifierPrefix: domNodeId });
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
