import React from 'react';
import { Route, Routes } from 'react-router-dom';

import { PageA, PageB } from './Routes.imports-loadable';

class LoadableRoutes extends React.PureComponent {
  render() {
    return (
      <Routes>
        <Route path="A" Component={PageA} />
        <Route path="B" Component={PageB} />
      </Routes>
    );
  }
}

export default LoadableRoutes;
