import * as React from 'react';
import { RailsContext } from './types';
import { getReactServerComponent, getPreloadedReactServerComponents } from './getReactServerComponent.client';

type RSCContextType = {
  getCachedComponent: (componentName: string, componentProps: unknown) => React.ReactNode;

  getComponent: (componentName: string, componentProps: unknown) => Promise<React.ReactNode>;
};

const RSCContext = React.createContext<RSCContextType | undefined>(undefined);

export const createRSCProvider = async ({
  railsContext,
  getServerComponent,
  getPreloadedComponents,
}: {
  railsContext: RailsContext;
  getServerComponent: typeof getReactServerComponent;
  getPreloadedComponents?: typeof getPreloadedReactServerComponents;
}) => {
  const cachedComponents = (await getPreloadedComponents?.(railsContext)) ?? {};
  const getCachedComponent = (componentName: string, componentProps: unknown) => {
    const key = `${componentName}-${JSON.stringify(componentProps)}`;
    return cachedComponents[key];
  };

  const getComponent = async (componentName: string, componentProps: unknown) => {
    const cachedComponent = getCachedComponent(componentName, componentProps);
    if (cachedComponent) {
      return cachedComponent;
    }
    return getServerComponent({ componentName, componentProps, railsContext });
  };

  return ({ children }: { children: React.ReactNode }) => {
    // eslint-disable-next-line react/jsx-no-constructed-context-values
    return <RSCContext.Provider value={{ getCachedComponent, getComponent }}>{children}</RSCContext.Provider>;
  };
};

export const useRSC = () => {
  const context = React.useContext(RSCContext);
  if (!context) {
    throw new Error('useRSC must be used within a RSCProvider');
  }
  return context;
};
