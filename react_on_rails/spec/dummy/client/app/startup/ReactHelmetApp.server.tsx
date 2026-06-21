import React from 'react';
import { HelmetProvider, type HelmetDataContext } from '@dr.pogodin/react-helmet';
import { renderToString } from 'react-dom/server';
import type { RailsContext, ServerRenderResult } from 'react-on-rails/types';
import ReactHelmet, { type ReactHelmetProps } from '../components/ReactHelmet';

// This counterpart takes two params, so React on Rails identifies it as a generator function.
const ReactHelmetApp = (props: ReactHelmetProps, _railsContext: RailsContext): ServerRenderResult => {
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

export default ReactHelmetApp;
