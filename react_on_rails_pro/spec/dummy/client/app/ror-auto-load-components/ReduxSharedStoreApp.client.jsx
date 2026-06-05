'use client';

// Top level component for client side.
// Compare this to the ./ServerApp.jsx file which is used for server side rendering.

import React from 'react';
import { Provider } from 'react-redux';
import ReactOnRails from 'react-on-rails-pro';
import { hydrateRoot, createRoot } from 'react-dom/client';

import HelloWorldContainer from '../components/HelloWorldContainer';
import { wrapElementInStrictMode } from '../strictModeSupport';

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
  const element = wrapElementInStrictMode(
    <Provider store={store}>
      <HelloWorldContainer />
    </Provider>,
  );

  const domEl = document.getElementById(domNodeId);
  if (!domEl) {
    const renderMode = prerender ? 'hydrate' : 'render';
    throw new Error(
      `Cannot ${renderMode} ReduxSharedStoreApp because DOM element with id "${domNodeId}" was not found.`,
    );
  }

  const root = hydrateOrRender(domEl, element, prerender);

  // Return a teardown wrapper so React on Rails unmounts this root on Turbo/Turbolinks navigation
  // (page unload) or same-id node replacement instead of leaking it.
  return { teardown: () => root.unmount() };
};
