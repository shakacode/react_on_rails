import React from 'react';
import HelloWorld from '../containers/HelloWorld';

const HelloWorldAppServer = props => {
  const reactComponent = (
    <HelloWorld {...props} />
  );
  return reactComponent;
};

export default HelloWorldAppServer;
