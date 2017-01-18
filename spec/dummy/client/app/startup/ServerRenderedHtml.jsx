// Top level component for simple client side only rendering
import React from 'react';
import { renderToString } from 'react-dom/server'
import EchoProps from '../components/EchoProps';

/*
 *  Export a function that takes the props and returns an object with { renderedHtml }
 *  Note, this is imported as "RenderedHtml" by "serverRegistration.jsx"
 *
 *  Note, this is a fictional example, as you'd only use a generator function if you wanted to run
 *  some extra code, such as setting up Redux and React-Router.
 *
 *  And the use of renderToString would probably be done with react-router v4
 *
 */
export default (props, railsContext) => {
  const renderedHtml = renderToString(
    <EchoProps {...props} />
  );
  return { renderedHtml };
};
