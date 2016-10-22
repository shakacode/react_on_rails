// Top level component for client side.
// Compare this to the ./ServerApp.jsx file which is used for server side rendering.

import React from 'react';
import { Provider } from 'react-redux';
import ReactOnRails from 'react-on-rails';

import HelloWorldContainer from '../components/HelloWorldContainer';

/*
 *  Export a function that returns a ReactComponent, depending on a store named SharedReduxStore.
 *  This is used for the client rendering hook after the page html is rendered.
 *  React will see that the state is the same and not do anything.
 */
export default () => {
  // This is where we get the existing store.
  const store = ReactOnRails.getStore('SharedReduxStore');

  return (
    <Provider store={store}>
      <HelloWorldContainer />
    </Provider>
    );
};
