// Top level component for client side.
// Compare this to the ./ServerApp.jsx file which is used for server side rendering.
// TODO: document that
// This file will export a function that will generate the client side rendering.
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

  // TODO: This is what will get exported.
  const AppContainer = (
    <Provider store={store}>
      {() => <HelloWorldContainer />}
    </Provider>
  );

  // TODO: Change to match component name by convention
  console.log("ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ");
  console.log("hello Samnang, about to client side render");
  console.log("ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ");

  // TODO: move this into the generated code, so that ID is unlikely to conflict with anything else
  // on the page!
  const appDOMNode = document.getElementById('app');
  React.render(AppContainer, appDOMNode);
};

// NOTE: The name App here matches up with the line above, and is not necessarily how this gets
// into server const App = (props) => {  HOWEVER, when this file is imported in
// ./serverGlobals.jsx, the exposed name 'App' is defined for server rendering by the import
// statement. NOTE: __appData__ MUST follow the naming convention, as we wrap with double
// underscores and append "Data" to the camelizedLower version of the component name ("App")
const appClientStartup = () => App(__appData__);

// TOOD CHANGE THIS TO RUN after document or page loaded
// Export the function!
appClientStartup();
