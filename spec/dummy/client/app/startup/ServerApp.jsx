// This is loaded by execJs and Rails to generate the HTML used for server rendering.
// Compare this file to ./ClientApp.jsx
// This module should export one default method that take props and returns the react component to
// render.

import React from 'react';
import { combineReducers } from 'redux';
import { applyMiddleware } from 'redux';
import { createStore } from 'redux';
import { Provider } from 'react-redux';
import middleware from 'redux-thunk';

// Uses the index
import reducers from '../reducers/reducersIndex';

import HelloWorldContainer from '../components/HelloWorldContainer';
import HelloWorld from '../components/HelloWorld';
import HelloES5 from '../components/HelloES5';

export default props => {
  const combinedReducer = combineReducers(reducers);

  // This is where we'll put in the middleware for the async function. Placeholder.
  // store will have helloWorldData as a top level property
  const store = applyMiddleware(middleware)(createStore)(combinedReducer, props);

  // Provider uses the this.props.children, so we're not typical React syntax.
  // This allows redux to add additional props to the HelloWorldContainer.
  return (
    <Provider store={store}>
      {() => <HelloWorldContainer />}
    </Provider>
  );
};

// This is an example of how to render a React component directly, without using Redux
export { HelloWorld, HelloES5 };
