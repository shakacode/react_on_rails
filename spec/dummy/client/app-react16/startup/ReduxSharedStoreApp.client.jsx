// Top level component for the client side.
// Compare this to the ./ReduxSharedStoreApp.server.jsx file which is used for server side rendering.

import React from 'react';
import { Provider } from 'react-redux';
import ReactOnRails from 'react-on-rails/client';
import ReactDOM from 'react-dom';

import HelloWorldContainer from '../../app/components/HelloWorldContainer';

/*
 *  Export a function that returns a ReactComponent, depending on a store named SharedReduxStore.
 *  This is used for the client rendering hook after the page html is rendered.
 *  React will see that the state is the same and not do anything.
 */
export default (props, _railsContext, domNodeId) => {
  const render = props.prerender ? ReactDOM.hydrate : ReactDOM.render;
  // eslint-disable-next-line no-param-reassign
  delete props.prerender;

  // This is where we get the existing store.
  const store = ReactOnRails.getStore('SharedReduxStore');

  // renderApp is a function required for hot reloading. see
  // https://github.com/retroalgic/react-on-rails-hot-minimal/blob/master/client/src/entry.js

  // Provider uses this.props.children, so we're not typical React syntax.
  // This allows redux to add additional props to the HelloWorldContainer.
  const renderApp = (Component) => {
    const element = (
      <Provider store={store}>
        <Component />
      </Provider>
    );
    render(element, document.getElementById(domNodeId));
  };

  renderApp(HelloWorldContainer);

  if (module.hot) {
    module.hot.accept(['../components/HelloWorldContainer'], () => {
      renderApp(HelloWorldContainer);
    });
  }
};
