import React from 'react';
import { Helmet } from 'react-helmet';
import HelloWorld from './HelloWorld';

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
