'use client';

// Top level component for simple client side only rendering
import React from 'react';
import { HelmetProvider } from '@dr.pogodin/react-helmet';
import ReactHelmet from '../components/ReactHelmet';

const stubbedResponse = { name: 'ReactOnRails', country: [], count: 0 };

// HelmetProvider is required by @dr.pogodin/react-helmet for both client and server rendering
export default (props, _railsContext) => () => (
  <HelmetProvider>
    <ReactHelmet {...props} apiRequestResponse={stubbedResponse} />
  </HelmetProvider>
);
