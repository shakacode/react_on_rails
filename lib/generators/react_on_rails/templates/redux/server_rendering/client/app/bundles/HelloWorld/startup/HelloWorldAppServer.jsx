import React from 'react';
import { Provider } from 'react-redux';

import createStore from '../store/helloWorldStore';
import HelloWorld from '../containers/HelloWorld';

// See documentation for https://github.com/rackt/react-redux.
// This is how you get props from the Rails view into the redux store.
// This code here binds your smart component to the redux store.
// This is how the server redux gets hydrated with data.
const HelloWorldAppServer = props => {
  const store = createStore(props);
  const reactComponent = (
    <Provider store={store}>
      <HelloWorld />
    </Provider>
  );
  return reactComponent;
};

export default HelloWorldAppServer;
