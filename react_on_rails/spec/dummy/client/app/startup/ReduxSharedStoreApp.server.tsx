import React from 'react';
import ReactOnRails from 'react-on-rails';
import { Provider } from 'react-redux';

import HelloWorldContainer from '../components/HelloWorldContainer';
import type { ReduxAppStore } from '../store/reduxTypes';

export default function ReduxSharedStoreApp() {
  const store = ReactOnRails.getStore('SharedReduxStore') as ReduxAppStore;

  return (
    <Provider store={store}>
      <HelloWorldContainer />
    </Provider>
  );
}
