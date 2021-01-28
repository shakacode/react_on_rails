import PropTypes from 'prop-types';
import React from 'react';
import { Link, Route, Switch } from 'react-router-dom';
import RouterFirstPage from './RouterFirstPage';
import RouterSecondPage from './RouterSecondPage';

const RouterLayout = ({ children }) => (
  <div className="container">
    <h1>React Router is working!</h1>
    <p>
      Woohoo, we can use <code>react-router</code> here!
    </p>
    <ul>
      <li>
        <Link to="/react_router">React Router Layout Only</Link>
      </li>
      <li>
        <Link to="/react_router/first_page">Router First Page</Link>
      </li>
      <li>
        <Link to="/react_router/second_page">Router Second Page</Link>
      </li>
    </ul>
    <hr />
    <Switch>
      <Route path="/react_router/first_page" component={RouterFirstPage} />
      <Route path="/react_router/second_page" component={RouterSecondPage} />
    </Switch>
  </div>
);

RouterLayout.propTypes = {
  children: PropTypes.object,
};

export default RouterLayout;
