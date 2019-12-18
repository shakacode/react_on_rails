import PropTypes from 'prop-types';
import React from 'react';
import { Link } from 'react-router';

const RouterLayout = ({ children }) => (
  <div className="container">
    <h1>React Router is working!</h1>
    <p>
      Woohoo, we can use <code>react-router</code> here!
    </p>
    <ul>
      <li>
        <Link to="/react_router" href="/react_router">
          React Router Layout Only
        </Link>
      </li>
      <li>
        <Link to="/react_router/first_page" href="/react_router/first_page">
          Router First Page
        </Link>
      </li>
      <li>
        <Link to="/react_router/second_page" href="/react_router/second_page">
          Router Second Page
        </Link>
      </li>
    </ul>
    <hr />
    {children}
  </div>
);

RouterLayout.propTypes = {
  children: PropTypes.object,
};

export default RouterLayout;
