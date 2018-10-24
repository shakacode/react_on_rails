import React from 'react';
import ReactDOM from 'react-dom';
import { match, Router, browserHistory } from 'react-router';

import DeferredRender from '../components/DeferredRender';

const DeferredRenderAppClient = (_props, _railsContext, domNodeId) => {
  const history = browserHistory;
  const routes = {
    path: '/deferred_render_with_server_rendering',
    component: DeferredRender,
    childRoutes: [{
      path: '/deferred_render_with_server_rendering/async_page',
      getComponent(_nextState, callback) {
        require.ensure([], (require) => {
          // https://webpack.js.org/api/module-methods/#require-ensure
          // callback: A function that webpack will execute once the dependencies are loaded. An
          // implementation of the require function is sent as a parameter to this function. The
          // function body can use this to further require() modules it needs for execution.
          // This is supeseded by import for Wepback v4
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
    ReactDOM.hydrate(reactElement, document.getElementById(domNodeId));
  });
};

export default DeferredRenderAppClient;
