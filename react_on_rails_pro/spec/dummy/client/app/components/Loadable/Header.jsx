import React from 'react';
import { Helmet } from 'react-helmet';
import ActiveLink from './ActiveLink';

const Header = () => (
  <div>
    <Helmet>
      <title>Index Page</title>
    </Helmet>
    <ActiveLink to="/page-a" text="Path A" />
    <ActiveLink to="/page-b" text="Path B" />
  </div>
);

export default Header;
