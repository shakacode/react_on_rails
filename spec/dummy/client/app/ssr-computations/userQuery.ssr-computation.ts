import { gql } from '@apollo/client';
import { NoResult } from '@shakacode/use-ssr-computation.runtime';
import { getApolloClient, initializeApolloClient } from '../utils/lazyApollo';
import { isSSR } from '../utils/dom';

const USER_QUERY = gql`
  query User($id: ID!) {
    user(id: $id) {
      id
      name
      email
    }
  }
`;

export const preloadQuery = (userId: number) => {
  const apolloClient = getApolloClient();
  if (!apolloClient) {
    throw new Error('Apollo client not found');
  }
  return apolloClient.query({
    query: USER_QUERY,
    variables: { id: userId },
  });
};

export const compute = (userId: number) => {
  const initializedApolloClient = getApolloClient();
  if (!initializedApolloClient && isSSR) {
    console.log('Apollo Client is not initialized on server-side before calling useSSRComputation');
  }

  const apolloClient = initializedApolloClient ?? initializeApolloClient();
  const data = apolloClient.cache.readQuery({
    query: USER_QUERY,
    variables: { id: userId },
  });
  return data ?? NoResult;
};

export const subscribe = (getCurrentResult: () => any, next: (result: any) => void, userId: number) => {
  const apolloClient = getApolloClient();
  if (!apolloClient) {
    throw new Error('Apollo client not found');
  }
  return apolloClient
    .watchQuery({
      query: USER_QUERY,
      variables: { id: userId },
    })
    .subscribe({
      next: (result) => {
        next(result.data);
      },
    });
};
