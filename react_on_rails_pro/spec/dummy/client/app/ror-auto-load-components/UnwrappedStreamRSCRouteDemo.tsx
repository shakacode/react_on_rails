'use client';

import React, { Suspense } from 'react';
import RSCRoute from 'react-on-rails-pro/RSCRoute';

const UnwrappedStreamRSCRouteDemo = () => (
  <section data-testid="unwrapped-stream-rsc-route-page">
    <h1>Unwrapped stream RSC route shell before</h1>
    <Suspense
      fallback={
        <aside data-testid="unwrapped-stream-rsc-route-fallback">Unwrapped stream route loading</aside>
      }
    >
      <RSCRoute componentName="SimpleComponent" componentProps={{}} ssr={false} />
    </Suspense>
    <footer>Unwrapped stream RSC route shell after</footer>
  </section>
);

export default UnwrappedStreamRSCRouteDemo;
