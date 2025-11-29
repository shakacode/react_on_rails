// Top level component for simple client side only rendering
import React from 'react';
import { HelmetProvider } from '@dr.pogodin/react-helmet';
import ReactHelmet from '../components/ReactHelmet';

// This works fine, React functional component:
// export default (props) => <ReactHelmet {...props} />;

// HelmetProvider is required by @dr.pogodin/react-helmet for both client and server rendering
export default (props) => (
  <HelmetProvider>
    <ReactHelmet {...props} />
  </HelmetProvider>
);

// Note, the server side has to be a Render-Function

// If you want a renderFunction, return a ReactComponent
// export default (props, _railsContext) => () => <ReactHelmet {...props} />;
