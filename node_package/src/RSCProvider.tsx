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
  const fetchRSCPromises: Record<string, Promise<React.ReactNode>> = {};

  const generateCacheKey = (componentName: string, componentProps: unknown) => {
    return `${componentName}-${JSON.stringify(componentProps)}-${railsContext.componentSpecificMetadata?.renderRequestId}`;
  };

  const getCachedComponent = (componentName: string, componentProps: unknown) => {
    const key = generateCacheKey(componentName, componentProps);
    return cachedComponents[key];
  };

  const getComponent = async (componentName: string, componentProps: unknown) => {
    const cachedComponent = getCachedComponent(componentName, componentProps);
    if (cachedComponent) {
      return cachedComponent;
    }
    const key = generateCacheKey(componentName, componentProps);
    if (key in fetchRSCPromises) {
      return fetchRSCPromises[key];
    }

    const promise = getServerComponent({ componentName, componentProps, railsContext }).then((rsc) => {
      cachedComponents[key] = rsc;
      return rsc;
    });
    fetchRSCPromises[key] = promise;
    return promise;
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
