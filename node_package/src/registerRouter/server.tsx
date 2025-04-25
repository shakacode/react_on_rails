import * as React from 'react';
import baseRegisterServerComponent from '../baseRegisterServerComponent/server';
import { RailsContext, ReactComponent } from '../types';

const registerRouter = (routers: Record<string, ReactComponent>) => {
  const WrapperComponent = ({
    componentName,
    componentProps,
    railsContext,
  }: {
    componentName: keyof typeof routers;
    componentProps: unknown;
    railsContext: RailsContext;
  }) => {
    const RouterComponent = routers[componentName];
    return (
      <RouterComponent
        railsContext={railsContext}
        {...(typeof componentProps === 'object' ? componentProps : {})}
      />
    );
  };
  baseRegisterServerComponent(WrapperComponent, routers);
};

export default registerRouter;
