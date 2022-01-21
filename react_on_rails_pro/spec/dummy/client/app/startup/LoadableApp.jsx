import React from 'react';
import { BrowserRouter, StaticRouter } from 'react-router-dom';

import Header from '../components/loadable/Header';
import Routes from '../components/loadable/routes/Routes';
import Letters from '../components/loadable/letters';

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
