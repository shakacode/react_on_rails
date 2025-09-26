'use client';

import React from 'react';
import { ApolloProvider, ApolloClient, InMemoryCache, createHttpLink } from '@apollo/client';
import { hydrateRoot } from 'react-dom/client';
import ApolloGraphQL from '../components/ApolloGraphQL';

export default (_props, _railsContext, domNodeId) => {
  const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
  // fulfill the store with the server data
  const initialState = window.__APOLLO_STATE__;

  const client = new ApolloClient({
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
  const el = document.getElementById(domNodeId);
  const App = (
    <ApolloProvider client={client}>
      <ApolloGraphQL />
    </ApolloProvider>
  );
  hydrateRoot(el, App);
};
