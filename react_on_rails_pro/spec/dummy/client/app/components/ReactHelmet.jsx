import React from 'react';
import { Helmet } from 'react-helmet';
import HelloWorld from '../ror-auto-load-components/HelloWorld';
import { consistentKeysReplacer } from '../utils/json';
const ReactHelmet = (props) => (
  <div>
    <Helmet>
      <title>Custom page title</title>
    </Helmet>
    Props: {JSON.stringify(props, consistentKeysReplacer)}
    <HelloWorld {...props} />
    <div>
      result from api request during server rendering:{' '}
      {JSON.stringify(props.apiRequestResponse, consistentKeysReplacer)}
    </div>
  </div>
);

export default ReactHelmet;
