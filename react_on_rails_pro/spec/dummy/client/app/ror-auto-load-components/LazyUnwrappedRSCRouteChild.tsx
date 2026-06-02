'use client';

import React from 'react';
import RSCRoute from 'react-on-rails-pro/RSCRoute';

const LazyUnwrappedRSCRouteChild = () => (
  <RSCRoute componentName="SimpleComponent" componentProps={{}} ssr={false} />
);

export default LazyUnwrappedRSCRouteChild;
