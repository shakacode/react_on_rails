import React from 'react';
import { Helmet } from '@dr.pogodin/react-helmet';
import ActiveLink from './ActiveLink';

const Header = () => (
  <div>
    <Helmet>
      <title>Index Page</title>
    </Helmet>
    <ActiveLink to="/A" text="Path A" />
    <ActiveLink to="/B" text="Path B" />
  </div>
);

export default Header;
