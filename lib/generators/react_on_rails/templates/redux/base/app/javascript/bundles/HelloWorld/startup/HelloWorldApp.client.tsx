import React from 'react';
import { Provider } from 'react-redux';

import configureStore from '../store/helloWorldStore';
import HelloWorldContainer from '../containers/HelloWorldContainer';

interface HelloWorldAppProps {
  name: string;
}

// See documentation for https://github.com/reactjs/react-redux.
// This is how you get props from the Rails view into the redux store.
// This code here binds your smart component to the redux store.
const HelloWorldApp: React.FC<HelloWorldAppProps> = (props) => (
  <Provider store={configureStore(props)}>
    <HelloWorldContainer />
  </Provider>
);

export default HelloWorldApp;
