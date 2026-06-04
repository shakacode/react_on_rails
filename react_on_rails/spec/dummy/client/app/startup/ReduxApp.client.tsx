import React, { type ReactNode } from 'react';
import ReactDOMClient from 'react-dom/client';
import { Provider } from 'react-redux';
import type { RailsContext } from 'react-on-rails/types';
import { applyMiddleware, combineReducers, legacy_createStore as createStore } from 'redux';
import { thunk } from 'redux-thunk';

import HelloWorldContainer from '../components/HelloWorldContainer';
import reducers from '../reducers/reducersIndex';
import { wrapElementInStrictMode } from '../strictModeSupport';
import composeInitialState from '../store/composeInitialState';
import type { ReduxAppStore } from '../store/reduxTypes';

declare const module: {
  hot?: {
    accept(dependencies: string[], callback: () => void): void;
  };
};

type DomRenderer = (domNode: Element, element: ReactNode) => void;
const hydrateOrRender = (shouldHydrate: boolean): DomRenderer =>
  shouldHydrate
    ? (domNode, element) => {
        ReactDOMClient.hydrateRoot(domNode, element);
      }
    : (domNode, element) => {
        const root = ReactDOMClient.createRoot(domNode);
        root.render(element);
      };

export default function ReduxApp(
  props: Record<string, unknown>,
  railsContext: RailsContext,
  domNodeId: string,
): void {
  const render = hydrateOrRender(Boolean(props.prerender));
  const combinedReducer = combineReducers(reducers);
  const combinedProps = composeInitialState(props, railsContext);
  const store: ReduxAppStore = createStore(combinedReducer, combinedProps, applyMiddleware(thunk));

  const renderApp = (Component: typeof HelloWorldContainer) => {
    const element = wrapElementInStrictMode(
      <Provider store={store}>
        <Component />
      </Provider>,
    );
    const domNode = document.getElementById(domNodeId);

    if (!domNode) {
      throw new Error(`Could not find DOM node with id '${domNodeId}' for ReduxApp.`);
    }

    render(domNode, element);
  };

  renderApp(HelloWorldContainer);

  if (module.hot) {
    module.hot.accept(['../reducers/reducersIndex', '../components/HelloWorldContainer'], () => {
      store.replaceReducer(combineReducers(reducers));
      renderApp(HelloWorldContainer);
    });
  }
}
