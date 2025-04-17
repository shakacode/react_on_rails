import * as React from 'react';
import { RSCClientRootProps } from './RSCClientRoot';
import { useRSC } from './RSCProvider';

const RSCRoute = ({ componentName, componentProps }: RSCClientRootProps) => {
  const { getComponent, getCachedComponent } = useRSC();
  let component = getCachedComponent(componentName, componentProps);
  if (!component) {
    component = React.use(getComponent(componentName, componentProps));
  }
  return component;
};

export default RSCRoute;
