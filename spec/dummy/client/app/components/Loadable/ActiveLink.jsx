import React from 'react';
import { Link, useMatch } from 'react-router-dom';

function ActiveLink({ text, to }) {
  const match = useMatch({
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
