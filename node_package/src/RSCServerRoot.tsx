import * as React from 'react';
import type { RenderFunction, RailsContext, ReactComponent } from './types/index.ts';
import getReactServerComponent from './getReactServerComponent.server.ts';
import { createRSCProvider } from './RSCProvider.tsx';

type RSCServerRootProps = { ServerComponentContainer: ReactComponent };

const RSCServerRoot: RenderFunction = (
  { ServerComponentContainer }: RSCServerRootProps,
  railsContext?: RailsContext,
) => {
  if (!railsContext) {
    throw new Error('RSCClientRoot: No railsContext provided');
  }

  const RSCProvider = createRSCProvider({
    railsContext,
    getServerComponent: getReactServerComponent,
  });

  const suspensableServerComponent = (
    <React.Suspense fallback={null}>
      <ServerComponentContainer />
    </React.Suspense>
  );

  const root = <RSCProvider>{suspensableServerComponent}</RSCProvider>;

  return () => root;
};

export default RSCServerRoot;
