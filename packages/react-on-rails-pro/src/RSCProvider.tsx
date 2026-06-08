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

import * as React from 'react';
import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useRef,
  useState,
  useTransition,
  type ReactNode,
} from 'react';
import type { ClientGetReactServerComponentProps } from './getReactServerComponent.client.ts';
import { createRSCPayloadKey } from './utils.ts';

type RSCContextType = {
  getComponent: (componentName: string, componentProps: unknown) => Promise<ReactNode>;

  refetchComponent: (
    componentName: string,
    componentProps: unknown,
    options?: { recoverOnError?: boolean },
  ) => Promise<ReactNode>;

  getRefetchVersion: (componentName: string, componentProps: unknown) => number;

  getSuccessfulVersion: (componentName: string, componentProps: unknown) => number;
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
  return ({ children }: { children: ReactNode }) => {
    const fetchRSCPromisesRef = useRef<Record<string, Promise<ReactNode>>>({});
    // TODO(#3564): these provider-lifetime caches grow with each unique
    // componentName+props key. Add LRU/TTL eviction when high-cardinality route
    // props become common enough for the retained ReactNode promises to matter.
    const lastSuccessfulRSCPromisesRef = useRef<Record<string, Promise<ReactNode>>>({});
    const refetchVersionsRef = useRef<Record<string, number>>({});
    // `versions` is a per-cache-key counter held in React state. Bumping it on
    // refetch (inside startTransition) is what makes <RSCRoute> consumers re-
    // render with the new promise from the cache while React keeps the old
    // tree visible until the new payload resolves.
    const [versions, setVersions] = useState<Record<string, number>>({});
    const [successfulVersions, setSuccessfulVersions] = useState<Record<string, number>>({});
    const [, startTransition] = useTransition();

    const getRefetchVersion = useCallback((componentName: string, componentProps: unknown) => {
      const key = createRSCPayloadKey(componentName, componentProps);
      return refetchVersionsRef.current[key] ?? 0;
    }, []);

    const getSuccessfulVersion = useCallback(
      (componentName: string, componentProps: unknown) => {
        const key = createRSCPayloadKey(componentName, componentProps);
        return successfulVersions[key] ?? 0;
      },
      [successfulVersions],
    );

    const markSuccessfulPromise = useCallback(
      (key: string, promise: Promise<ReactNode>, notifyRoutes = false) => {
        if (fetchRSCPromisesRef.current[key] !== promise) {
          return;
        }

        lastSuccessfulRSCPromisesRef.current[key] = promise;
        if (!notifyRoutes) {
          return;
        }

        startTransition(() => {
          setSuccessfulVersions((v) => ({ ...v, [key]: (v[key] ?? 0) + 1 }));
        });
      },
      [startTransition],
    );

    const getComponent = useCallback(
      (componentName: string, componentProps: unknown) => {
        const key = createRSCPayloadKey(componentName, componentProps);
        if (key in fetchRSCPromisesRef.current) {
          return fetchRSCPromisesRef.current[key];
        }

        const promise = getServerComponent({ componentName, componentProps }).then((payload) => {
          if (!(payload instanceof Error)) {
            markSuccessfulPromise(key, promise);
          }
          return payload;
        });
        fetchRSCPromisesRef.current[key] = promise;
        return promise;
      },
      [markSuccessfulPromise],
    );

    const refetchComponent = useCallback(
      (
        componentName: string,
        componentProps: unknown,
        { recoverOnError = false }: { recoverOnError?: boolean } = {},
      ) => {
        const key = createRSCPayloadKey(componentName, componentProps);
        refetchVersionsRef.current[key] = (refetchVersionsRef.current[key] ?? 0) + 1;
        let promise!: Promise<ReactNode>;
        const restoreLastSuccessfulPromise = () => {
          if (fetchRSCPromisesRef.current[key] !== promise) {
            return;
          }

          const lastSuccessfulPromise = lastSuccessfulRSCPromisesRef.current[key];
          // eslint-disable-next-line @typescript-eslint/no-misused-promises
          if (lastSuccessfulPromise) {
            fetchRSCPromisesRef.current[key] = lastSuccessfulPromise;
          } else {
            // eslint-disable-next-line @typescript-eslint/no-dynamic-delete
            delete fetchRSCPromisesRef.current[key];
          }

          startTransition(() => {
            setVersions((v) => ({ ...v, [key]: (v[key] ?? 0) + 1 }));
          });
        };

        promise = Promise.resolve()
          .then(() =>
            getServerComponent({
              componentName,
              componentProps,
              enforceRefetch: true,
            }),
          )
          .then(
            (payload) => {
              if (payload instanceof Error) {
                if (recoverOnError) {
                  restoreLastSuccessfulPromise();
                }
              } else {
                markSuccessfulPromise(key, promise, true);
              }
              return payload;
            },
            (error: unknown) => {
              if (recoverOnError) {
                restoreLastSuccessfulPromise();
              }
              throw error;
            },
          );
        fetchRSCPromisesRef.current[key] = promise;
        startTransition(() => {
          setVersions((v) => ({ ...v, [key]: (v[key] ?? 0) + 1 }));
        });
        return promise;
      },
      [markSuccessfulPromise, startTransition],
    );

    // `versions` and `successfulVersions` are intentionally load-bearing deps:
    // refetch writes bump `versions` so routes read the new cache promise, and
    // successful refetches bump `successfulVersions` so routes can clear
    // recoverable error state. Trade-off: each bump re-renders every useRSC()
    // consumer even when its cache key is unaffected. Each extra render is a
    // cache hit, but use a per-key subscription if this becomes a bottleneck.
    const contextValue = useMemo(
      () => ({ getComponent, refetchComponent, getRefetchVersion, getSuccessfulVersion }),
      // eslint-disable-next-line react-hooks/exhaustive-deps
      [getComponent, refetchComponent, getRefetchVersion, getSuccessfulVersion, versions],
    );

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
