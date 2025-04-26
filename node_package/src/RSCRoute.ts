import * as React from 'react';
import { useRSC } from './RSCProvider';

export type RSCRouteProps = {
  componentName: string;
  componentProps: unknown;
};

const RSCRoute = ({ componentName, componentProps }: RSCRouteProps) => {
  React.useEffect(() => {
    console.log('RSCRoute mounted for', componentName, '[DEBUG RSC]');

    return () => {
      console.log('RSCRoute unmounted for', componentName, '[DEBUG RSC]');
    };
  }, [componentName]);

  const { getComponent, getCachedComponent } = useRSC();
  let component = getCachedComponent(componentName, componentProps);
  if (!component) {
    console.log(`RSCRoute component ${componentName} not found, fetching`, '[DEBUG RSC]');
    component = React.use(getComponent(componentName, componentProps));
    console.log(`RSCRoute component ${componentName} fetched`, '[DEBUG RSC]');
  }
  return component;
};

export default RSCRoute;
