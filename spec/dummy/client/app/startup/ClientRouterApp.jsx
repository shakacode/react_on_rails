import React from 'react';
import Router from 'react-router';
import createHistory from 'history/lib/createBrowserHistory';
import routes from '../routes/routes';

export default (props) => {
  const history = createHistory();

  return (
    <Router history={history} children={routes} {...props} />
  );
};
