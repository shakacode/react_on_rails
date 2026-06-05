import React from 'react';
import type { ComponentProps } from 'react';
import { BrowserRouter } from 'react-router-dom';

import routes from '../routes/routes';

type RouterAppProps = {
  helloWorldData: {
    name: string;
  };
} & Omit<ComponentProps<typeof BrowserRouter>, 'children' | 'future'>;

const routerFuture: ComponentProps<typeof BrowserRouter>['future'] = {
  v7_startTransition: true,
  v7_relativeSplatPath: true,
};

const RouterApp = ({ helloWorldData: _helloWorldData, ...routerProps }: RouterAppProps) => (
  <BrowserRouter {...routerProps} future={routerFuture}>
    {routes}
  </BrowserRouter>
);

export default RouterApp;
