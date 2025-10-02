'use client';

import React from 'react';
import { renderToString } from 'react-dom/server';
import { getMarkupFromTree } from '@apollo/client/react/ssr';
import { ApolloClient, createHttpLink, InMemoryCache } from '@apollo/client';
import { getSSRCache } from '@shakacode/use-ssr-computation.runtime/lib/ssrCache';
import { RailsContext } from 'react-on-rails-pro';
import ApolloGraphQL from '../components/LazyApolloGraphQL';
import { preloadQuery } from '../ssr-computations/userQuery.ssr-computation';
import { setApolloClient } from '../utils/lazyApollo';

type Props = {
  ssrOnlyProps: {
    csrf: string;
    sessionCookie: string;
  };
};

export default async (props: Props, _railsContext: RailsContext) => {
  const { csrf, sessionCookie } = props.ssrOnlyProps;
  const client = new ApolloClient({
    ssrMode: true,
    link: createHttpLink({
      uri: 'http://localhost:3000/graphql',
      headers: {
        'X-CSRF-Token': csrf,
        Cookie: `_dummy_session=${sessionCookie}`,
      },
    }),
    cache: new InMemoryCache(),
  });
  setApolloClient(client);
  const App = <ApolloGraphQL />;

  // `ssr-computation` doesn't support async code on server side, so needs to preload the query before rendering
  await preloadQuery(1);
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
        __html: `
          window.__APOLLO_STATE__=${JSON.stringify(initialState).replace(/</g, '\\u003c')};
          window.__SSR_COMPUTATION_CACHE=${JSON.stringify(getSSRCache())};
        `,
      }}
    />,
  );
  return { componentHtml, apolloStateTag };
};
