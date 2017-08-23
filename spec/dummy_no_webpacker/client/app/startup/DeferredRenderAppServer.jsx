import React from 'react';
import { match, RouterContext } from 'react-router';

import DeferredRender from '../components/DeferredRender';
import DeferredRenderAsyncPage from '../components/DeferredRenderAsyncPage';

const DeferredRenderAppServer = (_props, railsContext) => {
  let error;
  let redirectLocation;
  let routerProps;

  const { location } = railsContext;
  const routes = {
    path: '/deferred_render_with_server_rendering',
    component: DeferredRender,
    childRoutes: [{
      path: '/deferred_render_with_server_rendering/async_page',
      component: DeferredRenderAsyncPage,
    }],
  };

  // Unlike the match in DeferredRenderAppRenderer, this match is always
  // syncronous because we directly require all the routes. Do not do anything
  // asyncronous in code that will run on the server.
  match({ location, routes }, (_error, _redirectLocation, _routerProps) => {
    error = _error;
    redirectLocation = _redirectLocation;
    routerProps = _routerProps;
  });

  if (error || redirectLocation) {
    return { error, redirectLocation };
  }

  return <RouterContext {...routerProps} />;
};

export default DeferredRenderAppServer;
