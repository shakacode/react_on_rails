// This is loaded by execJs and Rails to generate the HTML used for server rendering.
// Compare this file to ./ClientApp.jsx
// This module should export one default method that take props and returns the react component to
// render.

import React from 'react';
import { combineReducers, applyMiddleware, createStore } from 'redux';
import { Provider } from 'react-redux';
import middleware from 'redux-thunk';

// Uses the index
import reducers from '../reducers/reducersIndex';

import HelloWorldContainer from '../components/HelloWorldContainer';

/*
 *  Export a function that takes the props and returns a ReactComponent.
 */
export default (props) => {
  const combinedReducer = combineReducers(reducers);

  // This is where we'll put in the middleware for the async function. Placeholder.
  // store will have helloWorldData as a top level property
  const store = applyMiddleware(middleware)(createStore)(combinedReducer, props);

  // Provider uses the this.props.children, so we're not typical React syntax.
  // This allows redux to add additional props to the HelloWorldContainer.
  /* eslint-disable react/no-multi-comp */
  return (
    <Provider store={store}>
      <HelloWorldContainer />
    </Provider>
  );
};
