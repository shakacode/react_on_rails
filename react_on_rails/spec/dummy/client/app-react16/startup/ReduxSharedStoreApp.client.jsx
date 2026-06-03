// Top level component for the client side.
// Compare this to the ./ReduxSharedStoreApp.server.jsx file which is used for server side rendering.

import React from 'react';
import { Provider } from 'react-redux';
import ReactOnRails from 'react-on-rails/client';
import ReactDOM from 'react-dom';

import HelloWorldContainer from '../../app/components/HelloWorldContainer';
// Intentional cross-tree import: the React 16 dummy entries reuse the StrictMode helper from the
// React 19 `app/` tree. Keep the import path in sync if `app/strictModeSupport` is moved.
import { wrapElementInStrictMode } from '../../app/strictModeSupport';

/*
 *  Export a function that returns a ReactComponent, depending on a store named SharedReduxStore.
 *  This is used for the client rendering hook after the page html is rendered.
 *  React will see that the state is the same and not do anything.
 */
export default (props, _railsContext, domNodeId) => {
  const render = props.prerender ? ReactDOM.hydrate : ReactDOM.render;
  // eslint-disable-next-line no-param-reassign
  delete props.prerender;

  const domNode = document.getElementById(domNodeId);

  // This is where we get the existing store.
  const store = ReactOnRails.getStore('SharedReduxStore');

  // renderApp is a function required for hot reloading. see
  // https://github.com/retroalgic/react-on-rails-hot-minimal/blob/master/client/src/entry.js

  // Provider uses this.props.children, so we're not typical React syntax.
  // This allows redux to add additional props to the HelloWorldContainer.
  // The React 16/17 API re-renders into the same container idempotently, so hot reload reuses the
  // existing tree (no separate root to unmount first).
  const renderApp = (Component) => {
    const element = wrapElementInStrictMode(
      <Provider store={store}>
        <Component />
      </Provider>,
    );
    render(element, domNode);
  };

  renderApp(HelloWorldContainer);

  if (module.hot) {
    module.hot.accept(['../components/HelloWorldContainer'], () => {
      renderApp(HelloWorldContainer);
    });
  }

  // Return a teardown so React on Rails unmounts this tree on Turbo/Turbolinks navigation
  // (page unload) or same-id node replacement instead of leaking it. The React 16/17 API unmounts
  // by container node rather than via a root handle.
  return () => ReactDOM.unmountComponentAtNode(domNode);
};
