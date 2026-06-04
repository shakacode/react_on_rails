import React from 'react';
import type { ComponentProps } from 'react';
import { StaticRouter } from 'react-router-dom/server';
import type { RailsContext } from 'react-on-rails/types';

import routes from '../routes/routes';

type RouterAppProps = {
  helloWorldData: {
    name: string;
  };
} & Omit<ComponentProps<typeof StaticRouter>, 'children' | 'location'>;

const RouterApp = (props: RouterAppProps, railsContext: RailsContext) => () => (
  <StaticRouter location={railsContext.location} {...props}>
    {routes}
  </StaticRouter>
);

export default RouterApp;
