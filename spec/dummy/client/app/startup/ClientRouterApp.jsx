import React from 'react';
import Router from 'react-router';
import createHistory from 'history/lib/createBrowserHistory';
import routes from '../routes/routes';

const RouterApp = (props) => {
  const history = createHistory();

  return (
    <Router history={history} children={routes} {...props} />
  );
};

RouterApp.generatorFunction = true;

export default RouterApp;
