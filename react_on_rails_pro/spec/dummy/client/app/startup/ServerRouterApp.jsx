import React from 'react';
import { match, RouterContext } from 'react-router';

import routes from '../routes/routes';

export default (_props, railsContext) => {
  let error;
  let redirectLocation;
  let routeProps;

  const { location } = railsContext;

  // See https://github.com/reactjs/react-router/blob/master/docs/guides/ServerRendering.md
  match({ routes, location }, (_error, _redirectLocation, _routeProps) => {
    error = _error;
    redirectLocation = _redirectLocation;
    routeProps = _routeProps;
  });

  // This tell react_on_rails to skip server rendering any HTML. Note, client rendering
  // will handle the redirect. What's key is that we don't try to render.
  // Critical to return the Object properties to match this { error, redirectLocation }
  if (error || redirectLocation) {
    return { error, redirectLocation };
  }

  // Important that you don't do this if you are redirecting or have an error.
  return (
    <RouterContext {...routeProps} />
  );
};
