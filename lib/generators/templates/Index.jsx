import React from 'react';
import { Router, IndexRoute, Route, hashHistory } from 'react-router';

import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import ReduxPromise from 'redux-promise';

import App from './App';
import reducers from './reducers';

const createStoreWithMiddleware = applyMiddleware(ReduxPromise)(createStore);

// railsContext provides contextual information especially useful for server rendering, such as
// knowing the locale. See the React on Rails documentation for more info on the railsContext

const Index = (props, _railsContext) => (
  <Provider store={createStoreWithMiddleware(reducers)}>
    <App />
  </Provider>
);

export default Index;
