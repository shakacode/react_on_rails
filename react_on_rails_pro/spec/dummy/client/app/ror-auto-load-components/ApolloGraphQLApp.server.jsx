'use client';

import React from 'react';
import { renderToString } from 'react-dom/server';
import { ApolloProvider, ApolloClient, createHttpLink, InMemoryCache } from '@apollo/client';
import { getMarkupFromTree } from '@apollo/client/react/ssr';
import fetch from 'cross-fetch';
import ApolloGraphQL from '../components/ApolloGraphQL';

export default async (props, _railsContext) => {
  const { csrf, sessionCookie } = props.ssrOnlyProps;
  const client = new ApolloClient({
    ssrMode: true,
    link: createHttpLink({
      uri: 'http://localhost:3000/graphql',
      headers: {
        'X-CSRF-Token': csrf,
        Cookie: `_dummy_session=${sessionCookie}`,
      },
      fetch,
    }),
    cache: new InMemoryCache(),
  });
  const App = (
    <ApolloProvider client={client}>
      <ApolloGraphQL />
    </ApolloProvider>
  );

  const componentHtml = await getMarkupFromTree({
    renderFunction: renderToString,
    tree: App,
  });

  const initialState = client.extract();

  // you need to return additional property `apolloStateTag`, to fulfill the state for hydration
  const apolloStateTag = renderToString(
    <script
      // eslint-disable-next-line react/no-danger
      dangerouslySetInnerHTML={{
        __html: `window.__APOLLO_STATE__=${JSON.stringify(initialState).replace(/</g, '\\u003c')};`,
      }}
    />,
  );
  return { componentHtml, apolloStateTag };
};
