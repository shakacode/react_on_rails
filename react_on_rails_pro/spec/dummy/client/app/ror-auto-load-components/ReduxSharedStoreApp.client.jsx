'use client';

// Top level component for client side.
// Compare this to the ./ServerApp.jsx file which is used for server side rendering.

import React from 'react';
import { Provider } from 'react-redux';
import ReactOnRails from 'react-on-rails-pro';
import { hydrateRoot, createRoot } from 'react-dom/client';

import HelloWorldContainer from '../components/HelloWorldContainer';

const hydrateOrRender = (domEl, reactEl, prerender) => {
  if (prerender) {
    return hydrateRoot(domEl, reactEl);
  }

  const root = createRoot(domEl);
  root.render(reactEl);
  return root;
};

/*
 *  Export a function that returns a ReactComponent, depending on a store named SharedReduxStore.
 *  This is used for the client rendering hook after the page html is rendered.
 *  React will see that the state is the same and not do anything.
 */
export default (props, _railsContext, domNodeId) => {
  const { prerender } = props;

  // This is where we get the existing store.
  const store = ReactOnRails.getStore('SharedReduxStore');

  // Provider uses this.props.children, so we're not typical React syntax.
  // This allows redux to add additional props to the HelloWorldContainer.
  const element = (
    <Provider store={store}>
      <HelloWorldContainer />
    </Provider>
  );

  hydrateOrRender(document.getElementById(domNodeId), element, prerender);
};
