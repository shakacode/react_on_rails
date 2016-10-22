// Top level component for serer side.
// Compare this to the ./ClientReduxSharedStoreApp.jsx file which is used for client side rendering.

import React from 'react';
import ReactOnRails from 'react-on-rails';
import { Provider } from 'react-redux';

import HelloWorldContainer from '../components/HelloWorldContainer';

/*
 *  Export a function that returns a ReactComponent, depending on a store named SharedReduxStore.
 *  This is used for the server rendering.
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
