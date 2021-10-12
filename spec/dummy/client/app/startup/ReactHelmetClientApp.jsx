// Top level component for simple client side only rendering
import React from 'react';
import ReactHelmet from '../components/ReactHelmet';

const stubbedResponse = { name: 'ReactOnRails', country: [] };

export default (props, _railsContext) => () => (
  <ReactHelmet {...props} apiRequestResponse={stubbedResponse} />
);
