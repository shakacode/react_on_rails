import React from 'react';

import RouterLayout from '../components/RouterLayout';
import RouterFirstPage from '../components/RouterFirstPage';
import RouterSecondPage from '../components/RouterSecondPage';

const loaderFunction = () => {
  console.log("/react_router's loader function was called.");
  return "return result from /react_router's loader function";
};

export default [
  {
    path: '/react_router',
    element: <RouterLayout />,
    loader: loaderFunction,
    children: [
      {
        path: 'first_page',
        element: <RouterFirstPage />,
        loader: loaderFunction,
      },
      {
        path: 'second_page',
        element: <RouterSecondPage />,
        loader: loaderFunction,
      },
    ],
  },
];
