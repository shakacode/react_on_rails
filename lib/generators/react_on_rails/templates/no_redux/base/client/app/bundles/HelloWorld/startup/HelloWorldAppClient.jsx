import React from 'react';
import HelloWorld from '../containers/HelloWorld';

const HelloWorldAppClient = props => {
  const reactComponent = (
    <HelloWorld {...props} />
  );
  return reactComponent;
};

export default HelloWorldAppClient;
