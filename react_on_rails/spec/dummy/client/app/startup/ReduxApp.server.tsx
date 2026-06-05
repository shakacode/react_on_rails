import React from 'react';
import { Provider } from 'react-redux';
import type { RailsContext } from 'react-on-rails/types';
import { applyMiddleware, combineReducers, legacy_createStore as createStore } from 'redux';
import { thunk } from 'redux-thunk';

import HelloWorldContainer from '../components/HelloWorldContainer';
import reducers from '../reducers/reducersIndex';
import composeInitialState from '../store/composeInitialState';
import type { ReduxAppStore } from '../store/reduxTypes';

export default function ReduxApp(props: Record<string, unknown>, railsContext: RailsContext) {
  const combinedReducer = combineReducers(reducers);
  const combinedProps = composeInitialState(props, railsContext);
  const store: ReduxAppStore = createStore(combinedReducer, combinedProps, applyMiddleware(thunk));

  const ReduxAppComponent = () => (
    <Provider store={store}>
      <HelloWorldContainer />
    </Provider>
  );

  return ReduxAppComponent;
}
