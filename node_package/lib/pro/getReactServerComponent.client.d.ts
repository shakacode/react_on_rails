import * as React from 'react';
import { RailsContext } from '../types/index.ts';

declare global {
  interface Window {
    REACT_ON_RAILS_RSC_PAYLOADS?: Record<string, string[]>;
  }
}
export type ClientGetReactServerComponentProps = {
  componentName: string;
  componentProps: unknown;
  enforceRefetch?: boolean;
};
/**
 * Creates a function that fetches and renders a server component on the client side.
 *
 * This style of higher-order function is necessary as the function that gets server components
 * on server has different parameters than the function that gets them on client. The environment
 * dependent parameters (domNodeId, railsContext) are passed from the `wrapServerComponentRenderer`
 * function, while the environment agnostic parameters (componentName, componentProps, enforceRefetch)
 * are passed from the RSCProvider which is environment agnostic.
 *
 * The returned function:
 * 1. Checks for embedded RSC payloads in window.REACT_ON_RAILS_RSC_PAYLOADS using the domNodeId
 * 2. If found, uses the embedded payload to avoid an HTTP request
 * 3. If not found (during client navigation or dynamic rendering), fetches via HTTP
 * 4. Processes the RSC payload into React elements
 *
 * The embedded payload approach ensures optimal performance during initial page load,
 * while the HTTP fallback enables dynamic rendering after navigation.
 *
 * @param domNodeId - The DOM node ID to create a unique key for the RSC payload store
 * @param railsContext - Context for the current request, shared across all components
 * @returns A function that accepts RSC parameters and returns a Promise resolving to the rendered React element
 *
 * The returned function accepts:
 * @param componentName - Name of the server component to render
 * @param componentProps - Props to pass to the server component
 * @param enforceRefetch - Whether to enforce a refetch of the component
 *
 * @important This is an internal function. End users should not use this directly.
 * Instead, use the useRSC hook which provides getComponent and refetchComponent functions
 * for fetching or retrieving cached server components. For rendering server components,
 * consider using RSCRoute component which handles the rendering logic automatically.
 */
declare const getReactServerComponent: (
  domNodeId: string,
  railsContext: RailsContext,
) => ({
  componentName,
  componentProps,
  enforceRefetch,
}: ClientGetReactServerComponentProps) => Promise<React.ReactNode>;
export default getReactServerComponent;
