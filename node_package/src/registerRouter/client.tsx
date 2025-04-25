import * as React from 'react';
import baseRegisterServerComponent from '../baseRegisterServerComponent/client';
import { ReactComponent } from '../types';

const registerRouter = (routers: Record<string, ReactComponent>) => {
  const WrapperComponent = ({
    componentName,
    componentProps,
  }: {
    componentName: keyof typeof routers;
    componentProps: unknown;
  }) => {
    const RouterComponent = routers[componentName];
    return <RouterComponent {...(typeof componentProps === 'object' ? componentProps : {})} />;
  };
  baseRegisterServerComponent(WrapperComponent, ...Object.keys(routers));
};

export default registerRouter;
