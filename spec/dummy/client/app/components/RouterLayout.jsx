import React from 'react';
import { Link, Outlet, useLoaderData } from 'react-router-dom';

const RouterLayout = () => {
  console.log(
    `The result of react-router's loaderFunction (which is called when then route is initialized) is: ${useLoaderData()}`,
  );
  return (
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
      <Outlet />
    </div>
  );
};

export default RouterLayout;
