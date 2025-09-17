import React from 'react';
import { Provider } from 'react-redux';

import configureStore, { RailsProps } from '../store/helloWorldStore';
import HelloWorldContainer from '../containers/HelloWorldContainer';

// Props interface matches what Rails will pass from the controller
type HelloWorldAppProps = RailsProps;

// See documentation for https://github.com/reactjs/react-redux.
// This is how you get props from the Rails view into the redux store.
// This code here binds your smart component to the redux store.
const HelloWorldApp: React.FC<HelloWorldAppProps> = (props) => (
  <Provider store={configureStore(props)}>
    <HelloWorldContainer />
  </Provider>
);

export default HelloWorldApp;
