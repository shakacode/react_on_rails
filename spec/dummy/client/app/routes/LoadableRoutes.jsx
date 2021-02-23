import React from 'react';
import { withRouter, Route, Switch } from 'react-router-dom';

import { PageA, PageB } from './LoadableRoutes.imports-loadable';

class Routes extends React.PureComponent {
  render() {
    const { basename } = this.props;
    return (
      <Switch>
        <Route path="/page-a">
          <PageA />
        </Route>
        <Route path="/page-b">
          <PageB />
        </Route>
      </Switch>
    );
  }
}

export default withRouter(Routes);
