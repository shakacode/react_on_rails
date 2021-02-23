import React from 'react';
import { Link, useRouteMatch } from 'react-router-dom';

function ActiveLink({ text, to }) {
  const match = useRouteMatch({
    path: to,
  });

  return (
    <div className={match ? 'active' : ''}>
      {match && '> '}
      <Link to={to}>{text}</Link>
    </div>
  );
}

export default ActiveLink;
