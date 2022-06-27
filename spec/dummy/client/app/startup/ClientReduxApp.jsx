// Top level component for client side.
// Compare this to the ./ServerApp.jsx file which is used for server side rendering.
// NOTE: these are basically the same, but they are shown here

import React from 'react';
import { combineReducers, applyMiddleware, createStore } from 'redux';
import { Provider } from 'react-redux';
import thunkMiddleware from 'redux-thunk';
import ReactDOMClient from 'react-dom/client';

import reducers from '../reducers/reducersIndex';
import composeInitialState from '../store/composeInitialState';

import HelloWorldContainer from '../components/HelloWorldContainer';

/*
 *  Export a function that takes the props and returns a ReactComponent.
 *  This is used for the client rendering hook after the page html is rendered.
 *  React will see that the state is the same and not do anything.
 *
 */
export default (props, railsContext, domNodeId) => {
  const render = props.prerender
    ? ReactDOMClient.hydrateRoot
    : (domNode, element) => {
        const root = ReactDOMClient.createRoot(domNode);
        root.render(element);
      };
  // eslint-disable-next-line no-param-reassign
  delete props.prerender;

  const combinedReducer = combineReducers(reducers);
  const combinedProps = composeInitialState(props, railsContext);

  // This is where we'll put in the middleware for the async function. Placeholder.
  // store will have helloWorldData as a top level property
  const store = createStore(combinedReducer, combinedProps, applyMiddleware(thunkMiddleware));

  // renderApp is a function required for hot reloading. see
  // https://github.com/retroalgic/react-on-rails-hot-minimal/blob/master/client/src/entry.js

  // Provider uses this.props.children, so we're not typical React syntax.
  // This allows redux to add additional props to the HelloWorldContainer.
  const renderApp = (Komponent) => {
    const element = (
      <Provider store={store}>
        <Komponent />
      </Provider>
    );

    render(document.getElementById(domNodeId), element);
  };

  renderApp(HelloWorldContainer);

  if (module.hot) {
    module.hot.accept(['../reducers/reducersIndex', '../components/HelloWorldContainer'], () => {
      store.replaceReducer(combineReducers(reducers));
      renderApp(HelloWorldContainer);
    });
  }
};
