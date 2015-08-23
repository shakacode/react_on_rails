import React                from 'react';
import { combineReducers }  from 'redux';
import { applyMiddleware }  from 'redux';
import { createStore }      from 'redux';
import { Provider }         from 'react-redux';
import middleware           from 'redux-thunk';

// Uses the index
import reducers        from '../reducers/reducersIndex';
import HelloWorldContainer  from '../components/HelloWorldContainer';

export default (props) => {

  const combinedReducer = combineReducers(reducers);

  // This is where we'll put in the middleware for the async function. Placeholder.
  // store will have helloWorldData as a top level property
  const store = applyMiddleware()(createStore)(combinedReducer, props);

  // Provider uses the this.props.children, so we're not typical React syntax.
  // This allows redux to add additional props to the HelloWorldContainer.
  return (
    <Provider store={store}>
      {() => <HelloWorldContainer />}
    </Provider>
  );

}
