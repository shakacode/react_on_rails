import * as React from 'react';
import { RailsContext } from './types/index.ts';
import getReactServerComponent from './getReactServerComponent.client.ts';

type RSCContextType = {
  getCachedComponent: (componentName: string, componentProps: unknown) => React.ReactNode;

  getComponent: (componentName: string, componentProps: unknown) => Promise<React.ReactNode>;
};

const RSCContext = React.createContext<RSCContextType | undefined>(undefined);

/**
 * Creates a provider context for React Server Components.
 *
 * RSCProvider is a foundational component that:
 * 1. Provides caching for server components to prevent redundant requests
 * 2. Manages the fetching of server components through getComponent
 * 3. Offers environment-agnostic access to server components
 *
 * This factory function accepts an environment-specific getServerComponent implementation,
 * allowing it to work correctly in both client and server environments.
 *
 * @param railsContext - Context for the current request
 * @param getServerComponent - Environment-specific function for fetching server components
 * @returns A provider component that wraps children with RSC context
 *
 * @important This is an internal function. End users should not use this directly.
 * Instead, use wrapServerComponentRenderer from 'react-on-rails/wrapServerComponentRenderer/client'
 * for client-side rendering or 'react-on-rails/wrapServerComponentRenderer/server' for server-side rendering.
 */
export const createRSCProvider = ({
  railsContext,
  getServerComponent,
}: {
  railsContext: RailsContext;
  getServerComponent: typeof getReactServerComponent;
}) => {
  const cachedComponents: Record<string, React.ReactNode> = {};
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

/**
 * Hook to access the RSC context within client components.
 *
 * This hook provides access to:
 * - getCachedComponent: For retrieving already rendered server components
 * - getComponent: For fetching and rendering server components
 *
 * It must be used within a component wrapped by RSCProvider (typically done
 * automatically by wrapServerComponentRenderer).
 *
 * @returns The RSC context containing methods for working with server components
 * @throws Error if used outside of an RSCProvider
 *
 * @example
 * ```tsx
 * const { getComponent } = useRSC();
 * const serverComponent = React.use(getComponent('MyServerComponent', props));
 * ```
 */
export const useRSC = () => {
  const context = React.useContext(RSCContext);
  if (!context) {
    throw new Error('useRSC must be used within a RSCProvider');
  }
  return context;
};
