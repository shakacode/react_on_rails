import React from 'react';
import { HelmetProvider } from '@dr.pogodin/react-helmet';
import Loadable from './LoadableApp';

// HelmetProvider is required by @dr.pogodin/react-helmet for both client and server rendering
const WrappedLoadable = (props, railsContext) => () => (
  <HelmetProvider>
    <Loadable {...props} path={railsContext.pathname} />
  </HelmetProvider>
);

export default WrappedLoadable;
