'use client';

import React from 'react';
import { createBrowserRouter, RouterProvider } from 'react-router-dom';

import routes from '../routes/routes';

const dataClientRouter = () => {
  const router = createBrowserRouter(routes);

  return <RouterProvider router={router} />;
};

export default dataClientRouter;
