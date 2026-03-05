'use client';

import React from 'react';
import {
  Link,
  Outlet,
  RouterProvider,
  createRootRoute,
  createRoute,
  createRouter,
  createBrowserHistory,
  createMemoryHistory,
} from '@tanstack/react-router';
import {
  createTanStackRouterRenderFunction,
  serverRenderTanStackAppAsync,
} from 'react-on-rails/tanstack-router';

const RootLayout = () => (
  <div className="container">
    <h1>TanStack Router is working!</h1>
    <p>
      Woohoo, we can use <code>tanstack-router</code> asynchronously here!
    </p>
    <ul>
      <li>
        <Link to="/tanstack_router_async">TanStack Router Async Layout Only</Link>
      </li>
      <li>
        <Link to="/tanstack_router_async/second_page">TanStack Router Async Second Page</Link>
      </li>
    </ul>
    <hr />
    <Outlet />
  </div>
);

const HomePage = () => <h2 id="tanstack-async-home-page">TanStack Router Async Home Page</h2>;
const SecondPage = () => <h2 id="tanstack-async-second-page">TanStack Router Async Second Page</h2>;

const rootRoute = createRootRoute({ component: RootLayout });
const homeRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/tanstack_router_async',
  component: HomePage,
});
const secondRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/tanstack_router_async/second_page',
  component: SecondPage,
});
const routeTree = rootRoute.addChildren([homeRoute, secondRoute]);

const options = {
  createRouter: () => createRouter({ routeTree }),
};

const deps = {
  RouterProvider,
  createMemoryHistory,
  createBrowserHistory,
};

const syncRenderFn = createTanStackRouterRenderFunction(options, deps);

const TanStackRouterAppAsync = (props, railsContext) => {
  const propsOrDefault = props || {};

  if (!railsContext) {
    throw new Error('TanStackRouterAppAsync requires railsContext');
  }

  if (railsContext.serverSide) {
    return serverRenderTanStackAppAsync(
      options,
      propsOrDefault,
      railsContext,
      RouterProvider,
      createMemoryHistory,
    ).then(({ appElement }) => appElement);
  }

  const result = syncRenderFn(propsOrDefault, railsContext);
  return () => result;
};

TanStackRouterAppAsync.renderFunction = true;

export default TanStackRouterAppAsync;
