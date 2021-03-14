import React from 'react';
import { BrowserRouter, StaticRouter } from 'react-router-dom';

import Header from '../components/Header';
import Routes from '../routes/Routes';
import Letters from '../components/letters';

const App = (props) => {
  if (typeof window === `undefined`) {
    return (
      <StaticRouter location={props.path} context={{}}>
        <Header />
        <Routes />
        <Letters />
      </StaticRouter>
    );
  }
  return (
    <BrowserRouter>
      <Header />
      <Routes />
      <Letters />
    </BrowserRouter>
  );
};

export default App;
