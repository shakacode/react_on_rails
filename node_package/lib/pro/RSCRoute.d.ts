import * as React from 'react';
/**
 * Renders a React Server Component inside a React Client Component.
 *
 * RSCRoute provides a bridge between client and server components, allowing server components
 * to be directly rendered inside client components. This component:
 *
 * 1. During initial SSR - Uses the RSC payload to render the server component and embeds the payload in the page
 * 2. During hydration - Uses the embedded RSC payload already in the page
 * 3. During client navigation - Fetches the RSC payload via HTTP
 *
 * @example
 * ```tsx
 * <RSCRoute componentName="MyServerComponent" componentProps={{ user }} />
 * ```
 *
 * @important Only use for server components whose props change rarely. Frequent prop changes
 * will cause network requests for each change, impacting performance.
 *
 * @important This component expects that the component tree that contains it is wrapped using
 * wrapServerComponentRenderer from 'react-on-rails/wrapServerComponentRenderer/client' for client-side
 * rendering or 'react-on-rails/wrapServerComponentRenderer/server' for server-side rendering.
 */
export type RSCRouteProps = {
  componentName: string;
  componentProps: unknown;
};
declare const RSCRoute: ({ componentName, componentProps }: RSCRouteProps) => React.ReactNode;
export default RSCRoute;
