// Top level component for client side.
// Compare this to the ./ServerApp.jsx file which is used for server side rendering.
// NOTE: these are basically the same, but they are shown here

import React from 'react';
import { combineReducers, applyMiddleware, createStore } from 'redux';
import { Provider } from 'react-redux';
import thunkMiddleware from 'redux-thunk';
import { hydrateRoot, createRoot } from 'react-dom/client';

import reducers from '../reducers/reducersIndex';
import composeInitialState from '../store/composeInitialState';

import HelloWorldContainer from '../components/HelloWorldContainer';

const hydrateOrRender = (domEl, reactEl, prerender) => {
  if (prerender) {
    return hydrateRoot(domEl, reactEl);
  } else {
    const root = createRoot(domEl);
    root.render(reactEl);
    return root;
  }
};

/*
 *  Export a function that takes the props and returns a ReactComponent.
 *  This is used for the client rendering hook after the page html is rendered.
 *  React will see that the state is the same and not do anything.
 *
 */
export default (props, railsContext, domNodeId) => {
  const { prerender, ...rest } = props;

  const combinedReducer = combineReducers(reducers);
  const combinedProps = composeInitialState(rest, railsContext);

  // This is where we'll put in the middleware for the async function. Placeholder.
  // store will have helloWorldData as a top level property
  const store = createStore(combinedReducer, combinedProps, applyMiddleware(thunkMiddleware));

  // Provider uses this.props.children, so we're not typical React syntax.
  // This allows redux to add additional props to the HelloWorldContainer.
  const element = (
    <Provider store={store}>
      <HelloWorldContainer />
    </Provider>
  );

  hydrateOrRender(document.getElementById(domNodeId), element, prerender);
};
