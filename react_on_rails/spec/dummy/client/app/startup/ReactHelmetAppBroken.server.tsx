import React from 'react';
import { HelmetProvider, type HelmetDataContext } from '@dr.pogodin/react-helmet';
import { renderToString } from 'react-dom/server';
import type { ServerRenderResult } from 'react-on-rails/types';
import ReactHelmet, { type ReactHelmetProps } from '../components/ReactHelmet';

// This one is broken in that the function takes one param, so it's not a generator
// function. The point of this is to provide a good error.
// Note that the function should take 2 params to identify this as a generator function.
// Alternately, the function could get the property of `.renderFunction = true` added to it.
const ReactHelmetAppBroken = (props: ReactHelmetProps): ServerRenderResult => {
  const helmetContext: HelmetDataContext = {};
  const componentHtml = renderToString(
    <HelmetProvider context={helmetContext}>
      <ReactHelmet {...props} />
    </HelmetProvider>,
  );
  const { helmet } = helmetContext;

  return {
    renderedHtml: {
      componentHtml,
      title: helmet?.title?.toString() || '',
    },
  };
};

export default ReactHelmetAppBroken;
