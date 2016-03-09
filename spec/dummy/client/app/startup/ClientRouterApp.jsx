import React from 'react';
import { Router, browserHistory } from 'react-router';
import routes from '../routes/routes';

export default (props) => (
  <Router history={browserHistory} children={routes} {...props} />
);
