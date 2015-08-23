import React                from 'react';
import { combineReducers }  from 'redux';
import { applyMiddleware }  from 'redux';
import { createStore }      from 'redux';
import { Provider }         from 'react-redux';
import middleware           from 'redux-thunk';

import reducers             from '../reducers/reducersIndex';
import HelloWorldContainer  from '../components/HelloWorldContainer';

const App = (props) => {

  const combinedReducer = combineReducers(reducers);
  const store = applyMiddleware()(createStore)(combinedReducer, props);

  const AppContainer = (
    <Provider store={store}>
      {() => <HelloWorldContainer />}
    </Provider>
  );

  // TODO: Change to match component name by convention
  const appDOMNode = document.getElementById('app');

  React.render(AppContainer, appDOMNode);
};

export default App(__DATA_FROM_RAILS__);
