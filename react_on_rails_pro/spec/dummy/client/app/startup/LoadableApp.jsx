import React from 'react';
import { BrowserRouter, StaticRouter } from 'react-router-dom';

import Header from '../components/Loadable/Header';
import Routes from '../routes/LoadableRoutes';

const basename = 'loadable';

const LoadableApp = (props) => {
  if (typeof window === `undefined`) {
    return (
      <StaticRouter basename={basename} location={props.path} context={{}}>
        <Header />
        <Routes />
      </StaticRouter>
    );
  }
  return (
    <BrowserRouter basename={basename}>
      <Header />
      <Routes />
    </BrowserRouter>
  );
};

export default LoadableApp;
