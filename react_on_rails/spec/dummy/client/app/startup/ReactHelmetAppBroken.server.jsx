// Top level component for simple client side only rendering
// This one is broken in that the function takes one param, so it's not a generator
// function. The point of this is to provide a good error.
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
 *  Note that the function should take 2 params to identify this as a generator function.
 *  Alternately, the function could get the property of `.renderFunction = true` added to it.
 */
export default (props) => {
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
  return { renderedHtml };
};
