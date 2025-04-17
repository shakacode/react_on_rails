import * as React from 'react';
import type { RenderFunction, RailsContext } from './types/index.ts';
import getReactServerComponent from './getReactServerComponent.server.ts';
import { createRSCProvider } from './RSCProvider.tsx';
import RSCRoute from './RSCRoute.ts';

type RSCServerRootProps = {
  componentName: string;
  componentProps: unknown;
};

const RSCServerRoot: RenderFunction = async (
  { componentName, componentProps }: RSCServerRootProps,
  railsContext?: RailsContext,
) => {
  if (!railsContext) {
    throw new Error('RSCClientRoot: No railsContext provided');
  }

  const RSCProvider = await createRSCProvider({
    railsContext,
    getServerComponent: getReactServerComponent,
  });

  // eslint-disable-next-line react/no-children-prop
  const root = React.createElement(RSCProvider, {
    children: React.createElement(RSCRoute, { componentName, componentProps }),
  });

  return () => root;
};

export default RSCServerRoot;
