import React from 'react';
import ReactDOM from 'react-dom';
import { match, Router, browserHistory } from 'react-router';

import DeferredRender from '../components/DeferredRender';

const DeferredRenderAppRenderer = (_props, _railsContext, domNodeId) => {
  const history = browserHistory;
  const routes = {
    path: '/deferred_render_with_server_rendering',
    component: DeferredRender,
    childRoutes: [{
      path: '/deferred_render_with_server_rendering/async_page',
      getComponent(_nextState, callback) {
        require.ensure([], (require) => {
          const component = require('../components/DeferredRenderAsyncPage').default;

          // The first argument of the getComponent callback is error
          callback(null, component);
        });
      },
    }],
  };

  // This match is potentially asyncronous, because one of the routes
  // implements an asyncronous getComponent. Since we do server rendering for this
  // component, immediately rendering a Router could cause a client/server
  // checksum mismatch.
  match({ history, routes }, (error, _redirectionLocation, routerProps) => {
    if (error) {
      throw error;
    }

    const reactElement = <Router {...routerProps} />;
    ReactDOM.render(reactElement, document.getElementById(domNodeId));
  });
};

export default DeferredRenderAppRenderer;
