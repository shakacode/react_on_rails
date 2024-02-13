import { fetchSubscriptions } from '@shakacode/use-ssr-computation.runtime';
import { useCallback, useEffect, useRef, useState } from 'react';
import type { DocumentNode } from 'graphql/language';
import type {
  ApolloClient,
  FetchResult,
  MutationOptions,
  NormalizedCacheObject,
  OperationVariables,
  TypedDocumentNode,
} from '@apollo/client';

export const useLazyMutation = <TData, TVariables extends OperationVariables>(
  loadMutation: () => Promise<DocumentNode | TypedDocumentNode<TData, TVariables>>,
  options?: MutationOptions<TData, TVariables>,
) => {
  const [result, setResult] = useState<FetchResult<TData> & { loading: boolean }>({ loading: false });
  const currentOptions = useRef(options);
  currentOptions.current = options;
  const isMounted = useRef(true);

  useEffect(() => {
    return () => {
      isMounted.current = false;
    };
  }, []);

  const execute = useCallback(
    async (variables: Partial<TVariables>) => {
      fetchSubscriptions();
      setResult({ loading: true });
      const [apolloClient, mutation] = await Promise.all([
        import('./lazyApollo').then((lazyApollo) => lazyApollo.initializeApolloClient()),
        loadMutation(),
      ]);

      if (!isMounted.current) return;
      const result = await (apolloClient as ApolloClient<NormalizedCacheObject>).mutate<TData, TVariables>({
        mutation,
        ...currentOptions.current,
        variables: {
          ...currentOptions.current?.variables,
          ...variables,
        } as TVariables,
      });
      if (!isMounted.current) return;
      setResult({ ...result, loading: false });
    },
    [loadMutation],
  );

  return [execute, result] as const;
};
