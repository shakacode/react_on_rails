'use client';

import React from 'react';
import { hydrateRoot } from 'react-dom/client';
import { setSSRCache } from '@shakacode/use-ssr-computation.runtime';
import { RailsContext } from 'react-on-rails-pro';
import ApolloGraphQL from '../components/LazyApolloGraphQL';
import { wrapElementInStrictMode } from '../strictModeSupport';

export default (_props: unknown, _railsContext: RailsContext, domNodeId: string) => {
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
  const App = wrapElementInStrictMode(<ApolloGraphQL />);
  const root = hydrateRoot(el, App);

  // Return a teardown wrapper so React on Rails unmounts this root on Turbo/Turbolinks navigation
  // (page unload) or same-id node replacement instead of leaking it.
  return { teardown: () => root.unmount() };
};
