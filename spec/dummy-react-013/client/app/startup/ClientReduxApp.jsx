// Top level component for client side.
// Compare this to the ./ServerApp.jsx file which is used for server side rendering.

import React from 'react';
import { combineReducers } from 'redux';
import { applyMiddleware } from 'redux';
import { createStore } from 'redux';
import { Provider } from 'react-redux';
import ReactCompat from '../utils/ReactCompat';
import middleware from 'redux-thunk';

import reducers from '../reducers/reducersIndex';
import HelloWorldContainer from '../components/HelloWorldContainer';

/*
 *  Export a function that takes the props and returns a ReactComponent.
 *  This is used for the client rendering hook after the page html is rendered.
 *  React will see that the state is the same and not do anything.
 *
 */
const ReduxApp = props => {
  const combinedReducer = combineReducers(reducers);
  const store = applyMiddleware(middleware)(createStore)(combinedReducer, props);

  let reactComponent;
  if (ReactCompat.react013()) {
    reactComponent = (
      <Provider store={store}>
      {() => <HelloWorldContainer />}
      </Provider>
    );
  } else {
    reactComponent = (
      <Provider store={store}>
        <HelloWorldContainer />
      </Provider>
    );
  }

  return reactComponent;
};

/*
 * If you wish to create a React component via a function, rather than simply props,
 * then you need to set the property "generator" on that function to true.
 * When that is done, the function is invoked with a single parameter of "props",
 * and that function should return a react element.
 */

export default ReduxApp;
