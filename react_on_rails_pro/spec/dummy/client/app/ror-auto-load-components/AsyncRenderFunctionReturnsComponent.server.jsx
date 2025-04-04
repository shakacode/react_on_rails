// Top level component for simple client side only rendering
import React from 'react';
import EchoProps from '../components/EchoProps';

/*
 *  Export an async function that takes the props and returns a promise that resolves to a React component.
 *
 *  Note, this is a fictional example, as you'd only use a Render-Function if you wanted to run
 *  some extra code, such as setting up Redux and React Router.
 *
 */
export default async (props, _railsContext) => {
  await Promise.resolve();
  return () => <EchoProps {...props} />;
};
