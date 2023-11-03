import React from 'react';
import { renderToString } from 'react-dom/server';
import { createStaticHandler, createStaticRouter, StaticRouterProvider } from 'react-router-dom/server';

import routes from '../routes/routes';

const dataServerRouter = async (_props, railsContext) => {
  const controller = new AbortController();
  const request = new Request(new URL(railsContext.href), { signal: controller.signal });
  const handler = createStaticHandler(routes);
  const routerContext = await handler.query(request);
  const router = createStaticRouter(handler.dataRoutes, routerContext);

  return renderToString(<StaticRouterProvider router={router} context={routerContext} />);
};

export default dataServerRouter;
