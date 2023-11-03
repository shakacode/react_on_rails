import React from 'react';
import { BrowserRouter } from 'react-router-dom';
import { StaticRouter } from 'react-router-dom/server';

import Header from '../components/Loadable/Header';
import Routes from '../components/Loadable/routes/Routes';
import Letters from '../components/Loadable/letters';

const basename = 'loadable';

const LoadableApp = (props) => {
  if (typeof window === `undefined`) {
    return (
      <StaticRouter basename={basename} location={props.path} context={{}}>
        <Header />
        <Routes />
        <Letters />
      </StaticRouter>
    );
  }
  return (
    <BrowserRouter basename={basename}>
      <Header />
      <Routes />
      <Letters />
    </BrowserRouter>
  );
};

export default LoadableApp;
