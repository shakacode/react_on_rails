import * as React from 'react';
import type { ClientGetReactServerComponentProps } from './getReactServerComponent.client.ts';

type RSCContextType = {
  getComponent: (componentName: string, componentProps: unknown) => Promise<React.ReactNode>;
  refetchComponent: (componentName: string, componentProps: unknown) => Promise<React.ReactNode>;
};
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
export declare const createRSCProvider: ({
  getServerComponent,
}: {
  getServerComponent: (props: ClientGetReactServerComponentProps) => Promise<React.ReactNode>;
}) => ({ children }: { children: React.ReactNode }) => import('react/jsx-runtime').JSX.Element;
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
 * const serverComponent = React.use(getComponent('MyServerComponent', props));
 * ```
 */
export declare const useRSC: () => RSCContextType;
export {};
