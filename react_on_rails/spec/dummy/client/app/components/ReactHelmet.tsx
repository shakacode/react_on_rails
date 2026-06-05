import React from 'react';
import { Helmet } from '@dr.pogodin/react-helmet';
import HelloWorld, { type HelloWorldProps } from '../startup/HelloWorld';

type ReactHelmetProps = HelloWorldProps;

const ReactHelmet = (props: ReactHelmetProps) => (
  <div>
    <Helmet>
      <title>Custom page title</title>
    </Helmet>
    Props: {JSON.stringify(props)}
    <HelloWorld {...props} />
  </div>
);

export type { ReactHelmetProps };
export default ReactHelmet;
