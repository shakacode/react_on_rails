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
import composeInitialState from '../store/composeInitialState';

import HelloWorldContainer from '../components/HelloWorldContainer';

/*
 *  Export a function that takes the props and returns a ReactComponent.
 *  This is used for the server rendering.
 *  In the client, React will see that the state is the same and not do anything.
 */
export default (props, railsContext) => {
  // eslint-disable-next-line
  delete props.prerender;

  const combinedReducer = combineReducers(reducers);
  const combinedProps = composeInitialState(props, railsContext);

  // This is where we'll put in the middleware for the async function. Placeholder.
  // store will have helloWorldData as a top level property
  const store = applyMiddleware(middleware)(createStore)(combinedReducer, combinedProps);

  // Provider uses the this.props.children, so we're not typical React syntax.
  // This allows redux to add additional props to the HelloWorldContainer.
  return (
    <Provider store={store}>
      <HelloWorldContainer />
    </Provider>
  );
};
