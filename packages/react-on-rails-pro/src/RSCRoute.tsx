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

/// <reference types="react/experimental" />

'use client';

import * as React from 'react';
import {
  Component,
  createContext,
  forwardRef,
  use,
  useCallback,
  useContext,
  useImperativeHandle,
  useLayoutEffect,
  useMemo,
  useRef,
  type ReactNode,
} from 'react';
import { useRSC } from './RSCProvider.tsx';
import { RSCRouteSSRFalseBailoutError } from './RSCRouteSSRFalseBailoutError.ts';
import { isServerComponentFetchError, ServerComponentFetchError } from './ServerComponentFetchError.ts';
import { createRSCPayloadKey } from './utils.ts';

/**
 * Error boundary component for RSCRoute that adds server component name and props to the error
 * So, the parent ErrorBoundary can refetch the server component
 */
class RSCRouteErrorBoundary extends Component<
  { children: ReactNode; componentName: string; componentProps: unknown },
  { error: Error | null }
> {
  constructor(props: { children: ReactNode; componentName: string; componentProps: unknown }) {
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
 * Imperative handle exposed by `<RSCRoute>` via `ref`.
 *
 * `refetch()` re-fetches the server component using the RSCRoute's currently
 * rendered `componentName` and `componentProps`. It resolves with the new
 * rendered ReactNode and rejects with `ServerComponentFetchError` if the fetch
 * fails or the RSC payload resolves to an Error object.
 *
 * In production, client-control refetch failures are recoverable: the last
 * successful route content stays visible, `refetchError` is set, and `retry()`
 * can explicitly attempt the refetch again. Outside production, failures still
 * throw through the route so development diagnostics stay loud.
 *
 * Behavior caveats:
 * - **Concurrent refetches:** only the most-recent cache write wins; earlier
 *   returned promises may resolve with stale data while the UI has already
 *   moved on to a later refetch.
 * - **Unmount:** if the owning `<RSCRoute>` unmounts before resolution, the
 *   shared cache still updates (so other RSCRoutes bound to the same key
 *   reflect the new payload) but no visible re-render happens in the
 *   unmounted instance.
 */
export type RSCRouteHandle = {
  refetch: () => Promise<ReactNode>;
  retry: () => Promise<ReactNode>;
  refetchError: ServerComponentFetchError | null;
  clearRefetchError: () => void;
};

export type RSCRouteProps = {
  componentName: string;
  componentProps: unknown;
  ssr?: boolean;
  onRefetchError?: (error: ServerComponentFetchError) => void;
};

const CurrentRSCRouteContext = createContext<RSCRouteHandle | null>(null);

/**
 * Returns the `RSCRouteHandle` of the nearest ancestor `<RSCRoute>`, so a
 * client component rendered inside a server component subtree can refetch
 * that server component without knowing its name or props.
 *
 * @throws If called outside of any `<RSCRoute>` ancestor.
 *
 * @example
 * ```tsx
 * function InlineRefreshButton() {
 *   const { refetch } = useCurrentRSCRoute();
 *   return <button onClick={() => refetch().catch(console.error)}>Refresh</button>;
 * }
 * ```
 */
export function useCurrentRSCRoute(): RSCRouteHandle {
  const handle = useContext(CurrentRSCRouteContext);
  if (handle === null) {
    throw new Error('useCurrentRSCRoute must be used inside an <RSCRoute>');
  }
  return handle;
}

const PromiseWrapper = ({ promise }: { promise: Promise<ReactNode> }) => {
  // use is available in React 18.3+
  const promiseResult = use(promise);

  // In case that an error happened during the rendering of the RSC payload before the rendering of the component itself starts
  // RSC bundle will return an error object serialized inside the RSC payload
  if (promiseResult instanceof Error) {
    throw promiseResult;
  }

  return promiseResult;
};

const rejectErrorPayload = (promise: Promise<ReactNode>): Promise<ReactNode> =>
  promise.then((payload) => {
    if (payload instanceof Error) {
      throw payload;
    }
    return payload;
  });

const toServerComponentFetchError = (
  error: unknown,
  componentName: string,
  componentProps: unknown,
): ServerComponentFetchError => {
  if (isServerComponentFetchError(error)) {
    return error;
  }

  const originalError = error instanceof Error ? error : new Error(String(error));
  return new ServerComponentFetchError(originalError.message, componentName, componentProps, originalError);
};

type RefetchErrorState = {
  key: string;
  error: ServerComponentFetchError;
};

const RSCRouteContent = forwardRef<RSCRouteHandle, Omit<RSCRouteProps, 'ssr'>>(
  ({ componentName, componentProps, onRefetchError }, ref) => {
    const { getComponent, refetchComponent, getRefetchVersion, getSuccessfulVersion } = useRSC();
    const currentRouteKey = useMemo(
      () => createRSCPayloadKey(componentName, componentProps),
      [componentName, componentProps],
    );
    const successfulVersion = getSuccessfulVersion(componentName, componentProps);
    const [refetchErrorState, setRefetchErrorState] = React.useState<RefetchErrorState | null>(null);
    const refetchError = refetchErrorState?.key === currentRouteKey ? refetchErrorState.error : null;

    // Read the latest committed props in `refetch`, even when a descendant
    // captured the handle at an earlier render.
    const latestPropsRef = useRef({ componentName, componentProps });
    const latestRefetchRequestRef = useRef(0);
    const isMountedRef = useRef(false);
    useLayoutEffect(() => {
      isMountedRef.current = true;
      return () => {
        isMountedRef.current = false;
      };
    }, []);
    useLayoutEffect(() => {
      latestPropsRef.current = { componentName, componentProps };
    }, [componentName, componentProps]);
    useLayoutEffect(() => {
      setRefetchErrorState((state) => (state?.key === currentRouteKey ? state : null));
    }, [currentRouteKey]);
    useLayoutEffect(() => {
      setRefetchErrorState((state) => (state?.key === currentRouteKey ? null : state));
    }, [currentRouteKey, successfulVersion]);

    const refetch = useCallback((): Promise<ReactNode> => {
      const { componentName: n, componentProps: p } = latestPropsRef.current;
      const requestKey = createRSCPayloadKey(n, p);
      const requestId = latestRefetchRequestRef.current + 1;
      latestRefetchRequestRef.current = requestId;
      // refetchComponent swaps the cache promise and bumps the provider's
      // version inside startTransition. That re-renders every <RSCRoute>
      // (including this one) as a transition commit, so old content stays
      // visible while the new promise streams in.
      const refetchPromise = refetchComponent(n, p, {
        recoverOnError: process.env.NODE_ENV === 'production',
      });
      const sharedRefetchVersion = getRefetchVersion(n, p);
      return rejectErrorPayload(refetchPromise).then(
        (payload) => {
          if (isMountedRef.current) {
            setRefetchErrorState((state) =>
              latestRefetchRequestRef.current === requestId && state?.key === requestKey ? null : state,
            );
          }
          return payload;
        },
        (error: unknown) => {
          const serverComponentFetchError = toServerComponentFetchError(error, n, p);
          if (process.env.NODE_ENV === 'production') {
            const { componentName: latestName, componentProps: latestProps } = latestPropsRef.current;
            const latestRouteKey = createRSCPayloadKey(latestName, latestProps);
            if (
              isMountedRef.current &&
              latestRefetchRequestRef.current === requestId &&
              getRefetchVersion(n, p) === sharedRefetchVersion &&
              latestRouteKey === requestKey
            ) {
              setRefetchErrorState({ key: requestKey, error: serverComponentFetchError });
              onRefetchError?.(serverComponentFetchError);
            }
          }
          throw serverComponentFetchError;
        },
      );
    }, [getRefetchVersion, onRefetchError, refetchComponent]);

    const clearRefetchError = useCallback(() => {
      if (isMountedRef.current) {
        setRefetchErrorState((state) => (state?.key === currentRouteKey ? null : state));
      }
    }, [currentRouteKey]);

    const handle = useMemo<RSCRouteHandle>(
      () => ({ refetch, retry: refetch, refetchError, clearRefetchError }),
      [clearRefetchError, refetch, refetchError],
    );
    useImperativeHandle(ref, () => handle, [handle]);

    const componentPromise = getComponent(componentName, componentProps);
    return (
      <CurrentRSCRouteContext.Provider value={handle}>
        <RSCRouteErrorBoundary componentName={componentName} componentProps={componentProps}>
          <PromiseWrapper promise={componentPromise} />
        </RSCRouteErrorBoundary>
      </CurrentRSCRouteContext.Provider>
    );
  },
);

RSCRouteContent.displayName = 'RSCRouteContent';

/**
 * Renders a React Server Component inside a React Client Component.
 *
 * RSCRoute provides a bridge between client and server components, allowing server components
 * to be directly rendered inside client components. This component:
 *
 * 1. By default during initial SSR - Uses the RSC payload to render the server component and embeds the payload in the page
 * 2. During hydration - Uses the embedded RSC payload already in the page
 * 3. During client navigation - Fetches the RSC payload via HTTP
 *
 * Pass ssr={false} to skip rendering route content during streaming server rendering. When wrapped
 * in Suspense, React renders the nearest fallback in the server HTML and retries this route on the
 * client through the same RSC provider path used by the default ssr={true} mode.
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
const RSCRoute = forwardRef<RSCRouteHandle, RSCRouteProps>(
  ({ componentName, componentProps, ssr = true, onRefetchError }, ref): ReactNode => {
    if (!ssr && typeof window === 'undefined') {
      throw new RSCRouteSSRFalseBailoutError(componentName);
    }

    return (
      <RSCRouteContent
        ref={ref}
        componentName={componentName}
        componentProps={componentProps}
        onRefetchError={onRefetchError}
      />
    );
  },
);

RSCRoute.displayName = 'RSCRoute';

export default RSCRoute;
