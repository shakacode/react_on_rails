import * as React from 'react';
import * as ReactDOMClient from 'react-dom/client';
import { ReactComponentOrRenderFunction, RenderFunction } from '../types/index.ts';
import isRenderFunction from '../isRenderFunction.ts';
import { ensureReactUseAvailable } from '../reactApis.cts';
import { createRSCProvider } from '../RSCProvider.tsx';
import getReactServerComponent from '../getReactServerComponent.client.ts';

ensureReactUseAvailable();

const WrapServerComponentRenderer = (componentOrRenderFunction: ReactComponentOrRenderFunction) => {
  if (typeof componentOrRenderFunction !== 'function') {
    throw new Error('WrapServerComponentRenderer: component is not a function');
  }

  const wrapper: RenderFunction = async (props, railsContext, domNodeId) => {
    const Component = isRenderFunction(componentOrRenderFunction)
      ? await componentOrRenderFunction(props, railsContext, domNodeId)
      : componentOrRenderFunction;

    if (typeof Component !== 'function') {
      throw new Error('WrapServerComponentRenderer: component is not a function');
    }

    if (!railsContext) {
      throw new Error('RSCClientRoot: No railsContext provided');
    }

    const RSCProvider = createRSCProvider({
      railsContext,
      getServerComponent: getReactServerComponent,
    });

    const SuspensableRSCRoute = (
      <React.Suspense fallback={null}>
        <Component {...props} />
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

  return wrapper;
};

export default WrapServerComponentRenderer;
