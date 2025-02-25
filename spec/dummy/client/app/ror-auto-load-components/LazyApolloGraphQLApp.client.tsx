import React from 'react';
import { hydrateRoot } from 'react-dom/client';
import ApolloGraphQL from '../components/LazyApolloGraphQL';
import { setSSRCache } from '@shakacode/use-ssr-computation.runtime';
import { RailsContext } from 'react-on-rails';

export default (props: {}, _railsContext: RailsContext, domNodeId: string) => {
  if (!window.__SSR_COMPUTATION_CACHE) {
    throw new Error('Missing window.__SSR_COMPUTATION_CACHE');
  }
  const el = document.getElementById(domNodeId);
  if (!el) {
    throw new Error(`Missing DOM element with id: ${domNodeId}`);
  }

  console.log('window.__SSR_COMPUTATION_CACHE', window.__SSR_COMPUTATION_CACHE);
  const ssrComputationCache = window.__SSR_COMPUTATION_CACHE;
  setSSRCache(ssrComputationCache);
  const App = <ApolloGraphQL />;
  hydrateRoot(el, App);
};
