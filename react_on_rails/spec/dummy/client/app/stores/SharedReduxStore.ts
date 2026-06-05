import type { RailsContext } from 'react-on-rails/types';
import { applyMiddleware, combineReducers, legacy_createStore as createStore } from 'redux';
import { thunk } from 'redux-thunk';

import reducers from '../reducers/reducersIndex';
import composeInitialState from '../store/composeInitialState';
import type { ReduxAppStore } from '../store/reduxTypes';

export default function SharedReduxStore(
  props: Record<string, unknown>,
  railsContext: RailsContext,
): ReduxAppStore {
  const combinedReducer = combineReducers(reducers);

  return createStore(combinedReducer, composeInitialState(props, railsContext), applyMiddleware(thunk));
}
