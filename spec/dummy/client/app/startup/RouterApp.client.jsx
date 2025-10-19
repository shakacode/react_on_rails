import React from 'react';
import { BrowserRouter } from 'react-router-dom';
import routes from '../routes/routes';

export default (props) => (
  <BrowserRouter
    {...props}
    future={{
      v7_startTransition: true,
      v7_relativeSplatPath: true,
    }}
  >
    {routes}
  </BrowserRouter>
);
