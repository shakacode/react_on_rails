import React from 'react';
import ReactDOM from 'react-dom';
import { match, Router, browserHistory } from 'react-router';

import DeferredRender from '../components/DeferredRender';

const DeferredRenderAppClient = (_props, _railsContext, domNodeId) => {
  const history = browserHistory;
  const routes = {
    path: '/deferred_render_with_server_rendering',
    component: DeferredRender,
    childRoutes: [
      {
        path: '/deferred_render_with_server_rendering/async_page',
        async getComponent(_nextState, callback) {
          const component = await import(
            /* webpackChunkName: "deferredAsyncPage" */
            /* webpackPrefetch: true */
            /* webpackMode: "lazy" */
            '../components/DeferredRenderAsyncPage'
          );
          callback(null, component.default);
        },
      },
    ],
  };

  // This match is potentially asynchronous, because one of the routes
  // implements an asynchronous getComponent. Since we do server rendering for this
  // component, immediately rendering a Router could cause a client/server
  // checksum mismatch.
  match({ history, routes }, (error, _redirectionLocation, routerProps) => {
    if (error) {
      throw error;
    }

    const reactElement = <Router {...routerProps} />;
    ReactDOM.hydrate(reactElement, document.getElementById(domNodeId));
  });
};

export default DeferredRenderAppClient;
