import React from 'react';
import { Route } from 'react-router-dom';

import useRSC from './useRSC';

import type { RSCRouteProps } from './types/index';

export default function RSCRoute({ path, componentName, props }: RSCRouteProps): JSX.Element {
  const content = useRSC(componentName, props);
  return <Route path={path} render={() => content} />;
}
