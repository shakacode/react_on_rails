import React from 'react';
import { Helmet } from 'react-helmet';

const EchoProps = (props) => (
  <div>
    <Helmet>
      <title>Custom page title</title>
    </Helmet>
    Props: {JSON.stringify(props)}
  </div>
);

export default EchoProps;
