'use client';

import * as React from 'react';
import { BrowserRouter } from 'react-router-dom';
import wrapServerComponentRenderer from 'react-on-rails-pro/wrapServerComponentRenderer/client';
import App from '../components/ServerComponentRouter';

function ClientComponentRouter(props: object) {
  return (
    <BrowserRouter>
      <App {...props} />
    </BrowserRouter>
  );
}

export default wrapServerComponentRenderer(ClientComponentRouter);
