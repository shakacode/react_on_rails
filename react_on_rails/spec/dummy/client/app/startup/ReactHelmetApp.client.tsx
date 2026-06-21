import React from 'react';
import { HelmetProvider } from '@dr.pogodin/react-helmet';
import ReactHelmet, { type ReactHelmetProps } from '../components/ReactHelmet';

const ReactHelmetApp = (props: ReactHelmetProps) => (
  <HelmetProvider>
    <ReactHelmet {...props} />
  </HelmetProvider>
);

export default ReactHelmetApp;
