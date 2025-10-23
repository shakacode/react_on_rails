import React from 'react';
import { Link, Route, Routes } from 'react-router-dom';
import RouterFirstPage from './RouterFirstPage';
import RouterSecondPage from './RouterSecondPage';

const RouterLayout = () => (
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
    <Routes>
      <Route path="first_page" element={<RouterFirstPage />} />
      <Route path="second_page" element={<RouterSecondPage />} />
    </Routes>
  </div>
);

export default RouterLayout;
