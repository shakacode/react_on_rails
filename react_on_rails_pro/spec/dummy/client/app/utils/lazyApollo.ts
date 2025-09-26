import type { NormalizedCacheObject } from '@apollo/client';
import { ApolloClient, createHttpLink, InMemoryCache } from '@apollo/client';

export type AppApolloClient = ApolloClient<NormalizedCacheObject>;

let apolloClient: AppApolloClient | undefined;
export const getApolloClient = () => {
  return apolloClient;
};

export const setApolloClient = (client: AppApolloClient): void => {
  apolloClient = client;
};

export const initializeApolloClient = () => {
  let client = getApolloClient();
  if (client) {
    return client;
  }

  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
  if (!csrfToken) {
    throw new Error('CSRF token not found: Are you missing a meta tag in your layout?');
  }
  // fulfill the store with the server data
  const initialState = window.__APOLLO_STATE__;

  client = new ApolloClient({
    cache: new InMemoryCache().restore(initialState),
    link: createHttpLink({
      uri: `${window.location.origin}/graphql`,
      credentials: 'same-origin',
      headers: {
        'X-CSRF-Token': csrfToken,
      },
    }),
    ssrForceFetchDelay: 100,
  });

  setApolloClient(client);
  return client;
};
