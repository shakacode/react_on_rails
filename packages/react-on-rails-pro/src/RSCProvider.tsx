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

'use client';

import React, { createContext, useContext, type ReactNode } from 'react';
import type { ClientGetReactServerComponentProps } from './getReactServerComponent.client.ts';
import { createRSCPayloadKey } from './utils.ts';

type RSCContextType = {
  getComponent: (componentName: string, componentProps: unknown) => Promise<ReactNode>;

  refetchComponent: (componentName: string, componentProps: unknown) => Promise<ReactNode>;
};

const RSCContext = createContext<RSCContextType | undefined>(undefined);

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
  getServerComponent,
}: {
  getServerComponent: (props: ClientGetReactServerComponentProps) => Promise<ReactNode>;
}) => {
  const fetchRSCPromises: Record<string, Promise<ReactNode>> = {};

  const getComponent = (componentName: string, componentProps: unknown) => {
    const key = createRSCPayloadKey(componentName, componentProps);
    if (key in fetchRSCPromises) {
      return fetchRSCPromises[key];
    }

    const promise = getServerComponent({ componentName, componentProps });
    fetchRSCPromises[key] = promise;
    return promise;
  };

  const refetchComponent = (componentName: string, componentProps: unknown) => {
    const key = createRSCPayloadKey(componentName, componentProps);
    const promise = getServerComponent({
      componentName,
      componentProps,
      enforceRefetch: true,
    });
    fetchRSCPromises[key] = promise;
    return promise;
  };

  const contextValue = { getComponent, refetchComponent };

  return ({ children }: { children: ReactNode }) => {
    return <RSCContext.Provider value={contextValue}>{children}</RSCContext.Provider>;
  };
};

/**
 * Hook to access the RSC context within client components.
 *
 * This hook provides access to:
 * - getComponent: For fetching and rendering server components
 * - refetchComponent: For refetching server components
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
 * const serverComponent = use(getComponent('MyServerComponent', props));
 * ```
 */
export const useRSC = () => {
  const context = useContext(RSCContext);
  if (!context) {
    throw new Error('useRSC must be used within a RSCProvider');
  }
  return context;
};
