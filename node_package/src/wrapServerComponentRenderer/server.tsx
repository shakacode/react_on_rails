import * as React from 'react';
import type { RenderFunction, ReactComponentOrRenderFunction } from '../types';
import getReactServerComponent from '../getReactServerComponent.server';
import { createRSCProvider } from '../RSCProvider';
import isRenderFunction from '../isRenderFunction';

const WrapServerComponentRenderer = (componentOrRenderFunction: ReactComponentOrRenderFunction) => {
  if (typeof componentOrRenderFunction !== 'function') {
    throw new Error('WrapServerComponentRenderer: component is not a function');
  }

  const wrapper: RenderFunction = async (props, railsContext) => {
    if (!railsContext) {
      throw new Error('RSCClientRoot: No railsContext provided');
    }

    const Component = isRenderFunction(componentOrRenderFunction)
      ? await componentOrRenderFunction(props, railsContext)
      : componentOrRenderFunction;

    if (typeof Component !== 'function') {
      throw new Error('WrapServerComponentRenderer: component is not a function');
    }

    const RSCProvider = createRSCProvider({
      railsContext,
      getServerComponent: getReactServerComponent,
    });

    const suspensableServerComponent = (
      <React.Suspense fallback={null}>
        <Component {...props} />
      </React.Suspense>
    );

    const root = <RSCProvider>{suspensableServerComponent}</RSCProvider>;

    return () => root;
  };

  return wrapper;
};

export default WrapServerComponentRenderer;
