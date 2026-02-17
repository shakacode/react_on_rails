import React from 'react';

const RscEchoProps = (props) => (
  <div id="rsc-echo-props-result">
    <h2>RSC EchoProps</h2>
    <pre>{JSON.stringify(props, null, 2)}</pre>
  </div>
);

export default RscEchoProps;
