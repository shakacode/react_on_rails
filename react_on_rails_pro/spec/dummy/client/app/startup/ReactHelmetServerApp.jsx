// Top level component for simple client side only rendering
import React from 'react';
import { renderToString } from 'react-dom/server';
import { Helmet } from 'react-helmet';
import ReactHelmet from '../components/ReactHelmet';

/*
 *  Export a function that takes the props and returns an object with { renderedHtml }
 *  This example shows returning renderedHtml as an object itself that contains rendered
 *  component markup and additional HTML strings.
 *
 *  This is imported as "ReactHelmetApp" by "serverRegistration.jsx". Note that rendered
 *  component markup must go under "componentHtml" key.
 */
export default (props, _railsContext) => {
  const componentHtml = renderToString(<ReactHelmet {...props} />);
  const helmet = Helmet.renderStatic();

  const renderedHtml = {
    componentHtml,
    title: helmet.title.toString(),
  };
  return { renderedHtml };
};
