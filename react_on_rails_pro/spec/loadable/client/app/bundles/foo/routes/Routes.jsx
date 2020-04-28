import React from 'react';
import { withRouter, Route, Switch } from 'react-router-dom';

import { PageA, PageB } from './Routes.imports-loadable';

class Routes extends React.PureComponent {
  render() {
    return (
      <Switch>
        <Route path="/A">
          <PageA />
        </Route>
        <Route path="/B">
          <PageB />
        </Route>
      </Switch>
    );
  }
}

export default withRouter(Routes);
