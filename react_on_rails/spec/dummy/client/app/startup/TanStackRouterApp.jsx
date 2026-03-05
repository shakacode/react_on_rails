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
import { createTanStackRouterRenderFunction } from 'react-on-rails/tanstack-router';

const RootLayout = () => (
  <div className="container">
    <h1>TanStack Router is working!</h1>
    <p>
      Woohoo, we can use <code>tanstack-router</code> here!
    </p>
    <ul>
      <li>
        <Link to="/tanstack_router">TanStack Router Layout Only</Link>
      </li>
      <li>
        <Link to="/tanstack_router/second_page">TanStack Router Second Page</Link>
      </li>
    </ul>
    <hr />
    <Outlet />
  </div>
);

const HomePage = () => <h2 id="tanstack-home-page">TanStack Router Home Page</h2>;
const SecondPage = () => <h2 id="tanstack-second-page">TanStack Router Second Page</h2>;

const rootRoute = createRootRoute({ component: RootLayout });
const homeRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/tanstack_router',
  component: HomePage,
});
const secondRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/tanstack_router/second_page',
  component: SecondPage,
});

const routeTree = rootRoute.addChildren([homeRoute, secondRoute]);

const baseRenderFn = createTanStackRouterRenderFunction(
  {
    createRouter: () => createRouter({ routeTree }),
  },
  {
    RouterProvider,
    createMemoryHistory,
    createBrowserHistory,
  },
);

const TanStackRouterApp = (props, railsContext) => {
  const propsOrDefault = props || {};
  const result = baseRenderFn(propsOrDefault, railsContext);

  if (result && typeof result === 'object' && Object.prototype.hasOwnProperty.call(result, 'renderedHtml')) {
    return result;
  }

  return () => result;
};

TanStackRouterApp.renderFunction = true;

export default TanStackRouterApp;
