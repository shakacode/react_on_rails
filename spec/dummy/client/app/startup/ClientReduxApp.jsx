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
export default props => {
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
