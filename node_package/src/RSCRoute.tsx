import * as React from 'react';
import { useRSC } from './RSCProvider.tsx';
import { ServerComponentFetchError } from './ServerComponentFetchError.ts';

/**
 * Error boundary component for RSCRoute that adds server component name and props to the error
 * So, the parent ErrorBoundary can refetch the server component
 */
class RSCRouteErrorBoundary extends React.Component<
  { children: React.ReactNode; componentName: string; componentProps: unknown },
  { error: Error | null }
> {
  constructor(props: { children: React.ReactNode; componentName: string; componentProps: unknown }) {
    super(props);
    this.state = { error: null };
  }

  static getDerivedStateFromError(error: Error) {
    return { error };
  }

  render() {
    const { error } = this.state;
    const { componentName, componentProps, children } = this.props;
    if (error) {
      throw new ServerComponentFetchError(error.message, componentName, componentProps, error);
    }

    return children;
  }
}

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

const PromiseWrapper = ({ promise }: { promise: Promise<React.ReactNode> }) => {
  return React.use(promise);
};

const RSCRoute = ({ componentName, componentProps }: RSCRouteProps): React.ReactNode => {
  const { getComponent } = useRSC();
  const componentPromise = getComponent(componentName, componentProps);
  return (
    <RSCRouteErrorBoundary componentName={componentName} componentProps={componentProps}>
      <PromiseWrapper promise={componentPromise} />
    </RSCRouteErrorBoundary>
  );
};

export default RSCRoute;
