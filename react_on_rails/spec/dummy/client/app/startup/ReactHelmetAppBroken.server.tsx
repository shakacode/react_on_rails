import React from 'react';
import { HelmetProvider, type HelmetDataContext } from '@dr.pogodin/react-helmet';
import { renderToString } from 'react-dom/server';
import type { ServerRenderResult } from 'react-on-rails/types';
import ReactHelmet, { type ReactHelmetProps } from '../components/ReactHelmet';

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
