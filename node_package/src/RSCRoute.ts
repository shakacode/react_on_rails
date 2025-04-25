import * as React from 'react';
import { useRSC } from './RSCProvider';

export type RSCRouteProps = {
  componentName: string;
  componentProps: unknown;
};

const RSCRoute = ({ componentName, componentProps }: RSCRouteProps) => {
  const { getComponent, getCachedComponent } = useRSC();
  let component = getCachedComponent(componentName, componentProps);
  if (!component) {
    component = React.use(getComponent(componentName, componentProps));
  }
  return component;
};

export default RSCRoute;
