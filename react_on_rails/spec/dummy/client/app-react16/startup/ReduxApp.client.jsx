// Top level component for client side.
// Compare this to the ./ServerApp.jsx file which is used for server side rendering.
// NOTE: these are basically the same, but they are shown here

import React from 'react';
import { combineReducers, applyMiddleware, createStore } from 'redux';
import { Provider } from 'react-redux';
import { thunk } from 'redux-thunk';
import ReactDOM from 'react-dom';

import reducers from '../../app/reducers/reducersIndex';
import composeInitialState from '../../app/store/composeInitialState';

import HelloWorldContainer from '../../app/components/HelloWorldContainer';
// Intentional cross-tree import: the React 16 dummy entries reuse the StrictMode helper from the
// React 19 `app/` tree. Keep the import path in sync if `app/strictModeSupport` is moved.
import { wrapElementInStrictMode } from '../../app/strictModeSupport';

/*
 *  Export a function that takes the props and returns a ReactComponent.
 *  This is used for the client rendering hook after the page html is rendered.
 *  React will see that the state is the same and not do anything.
 *
 */
export default (props, railsContext, domNodeId) => {
  const { prerender, ...componentProps } = props;
  const render = prerender ? ReactDOM.hydrate : ReactDOM.render;

  const domNode = document.getElementById(domNodeId);
  if (!domNode) {
    const renderMode = prerender ? 'hydrate' : 'render';
    throw new Error(
      `Cannot ${renderMode} ReduxApp because DOM element with id "${domNodeId}" was not found.`,
    );
  }

  const combinedReducer = combineReducers(reducers);
  const combinedProps = composeInitialState(componentProps, railsContext);

  // This is where we'll put in the middleware for the async function. Placeholder.
  // store will have helloWorldData as a top level property
  const store = createStore(combinedReducer, combinedProps, applyMiddleware(thunk));

  // renderApp is a function required for hot reloading. see
  // https://github.com/retroalgic/react-on-rails-hot-minimal/blob/master/client/src/entry.js

  // Provider uses this.props.children, so we're not typical React syntax.
  // This allows redux to add additional props to the HelloWorldContainer.
  // The React 16/17 API re-renders into the same container idempotently, so hot reload reuses the
  // existing tree (no separate root to unmount first).
  const renderApp = (Komponent) => {
    const element = wrapElementInStrictMode(
      <Provider store={store}>
        <Komponent />
      </Provider>,
    );

    render(element, domNode);
  };

  renderApp(HelloWorldContainer);

  if (module.hot) {
    module.hot.accept(['../reducers/reducersIndex', '../components/HelloWorldContainer'], () => {
      store.replaceReducer(combineReducers(reducers));
      renderApp(HelloWorldContainer);
    });
  }

  // Return a teardown wrapper so React on Rails unmounts this tree on Turbo/Turbolinks navigation
  // (page unload) or same-id node replacement instead of leaking it. The React 16/17 API unmounts
  // by container node rather than via a root handle.
  return { teardown: () => ReactDOM.unmountComponentAtNode(domNode) };
};
