import { combineReducers, applyMiddleware, createStore } from 'redux';
import middleware from 'redux-thunk';

import reducers from '../reducers/reducersIndex';

/*
 *  Export a function that takes the props and returns a Redux store
 *  This is used so that 2 components can have the same store.
 */
export default props => {
  const combinedReducer = combineReducers(reducers);
  return applyMiddleware(middleware)(createStore)(combinedReducer, props);
};
