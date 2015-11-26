import React from 'react';
import Router from 'react-router';
import createHistory from 'history/lib/createBrowserHistory';
import routes from '../routes/routes';

const ClientRouterApp = (props) => {
  const history = createHistory();

  return (
    <div>
      <Router history={history} children={routes} {...props} />
    </div>
  );
};

// Export is needed for the hot reload server
export default ClientRouterApp;
