import React from 'react';
import { Helmet } from '@dr.pogodin/react-helmet';
import HelloWorld from '../startup/HelloWorld';

// Note: This component expects to be wrapped in a HelmetProvider by its parent.
// For client-side rendering, wrap in HelmetProvider at the app root.
// For server-side rendering, the server entry point provides the HelmetProvider.
const ReactHelmet = (props) => (
  <div>
    <Helmet>
      <title>Custom page title</title>
    </Helmet>
    Props: {JSON.stringify(props)}
    <HelloWorld {...props} />
  </div>
);

export default ReactHelmet;
