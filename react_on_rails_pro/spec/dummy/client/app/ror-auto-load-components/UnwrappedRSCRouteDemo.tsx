'use client';

import React, { Suspense } from 'react';

const LazyUnwrappedRSCRouteChild = React.lazy(() => import('./LazyUnwrappedRSCRouteChild'));

const UnwrappedRSCRouteDemo = () => (
  <section data-testid="unwrapped-rsc-route-page">
    <h1>Unwrapped RSC route shell before</h1>
    <Suspense
      fallback={<aside data-testid="unwrapped-rsc-route-fallback">Unwrapped deferred route loading</aside>}
    >
      <LazyUnwrappedRSCRouteChild />
    </Suspense>
    <footer>Unwrapped RSC route shell after</footer>
  </section>
);

export default UnwrappedRSCRouteDemo;
