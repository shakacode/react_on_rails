// Top level component for simple client side only rendering
import React from 'react';
import { renderToString } from 'react-dom/server';
import { HelmetProvider } from '@dr.pogodin/react-helmet';
import ReactHelmet from '../components/ReactHelmet';

/*
 *  Export a function that takes the props and returns an object with { renderedHtml }
 *  This example shows returning renderedHtml as an object itself that contains rendered
 *  component markup and additional HTML strings.
 *
 *  This is imported as "ReactHelmetApp" by "serverRegistration.jsx". Note that rendered
 *  component markup must go under "componentHtml" key.
 *
 *  Note that the function takes 2 params to identify this as a generator function. Alternately,
 *  the function could get the property of `.renderFunction = true` added to it.
 */
export default (props, _railsContext) => {
  // For server-side rendering with @dr.pogodin/react-helmet, we pass a context object
  // to HelmetProvider to capture the helmet data per-request (thread-safe)
  const helmetContext = {};

  const componentHtml = renderToString(
    <HelmetProvider context={helmetContext}>
      <ReactHelmet {...props} />
    </HelmetProvider>,
  );

  const { helmet } = helmetContext;

  const renderedHtml = {
    componentHtml,
    title: helmet ? helmet.title.toString() : '',
  };

  // Note that this function returns an Object for server rendering.
  return { renderedHtml };
};
