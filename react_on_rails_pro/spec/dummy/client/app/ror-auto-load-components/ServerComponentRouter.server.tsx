'use client';

import * as React from 'react';
import { StaticRouter } from 'react-router-dom/server.js';
import { RailsContext, ReactComponentOrRenderFunction } from 'react-on-rails-pro';
import wrapServerComponentRenderer from 'react-on-rails-pro/wrapServerComponentRenderer/server';
import App from '../components/ServerComponentRouter';

function ServerComponentRouter(props: object, railsContext: RailsContext) {
  const url = new URL(railsContext.href);
  const path = url.pathname;
  return () => (
    <StaticRouter location={path}>
      <App {...props} />
    </StaticRouter>
  );
}

export default wrapServerComponentRenderer(ServerComponentRouter as ReactComponentOrRenderFunction);
