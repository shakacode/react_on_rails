import React from 'react';
import { HelmetProvider } from '@dr.pogodin/react-helmet';
import ReactHelmet, { type ReactHelmetProps } from '../components/ReactHelmet';

const ReactHelmetAppBroken = (props: ReactHelmetProps) => (
  <HelmetProvider>
    <ReactHelmet {...props} />
  </HelmetProvider>
);

export default ReactHelmetAppBroken;
