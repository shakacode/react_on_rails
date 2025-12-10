'use client';

import path from 'path';
import React from 'react';
import { ChunkExtractor } from '@loadable/server';
import { renderToString } from 'react-dom/server';
import { HelmetProvider } from '@dr.pogodin/react-helmet';

import App from './LoadableApp';

const loadableApp = (props, railsContext) => {
  // Note, React on Rails Pro copies the loadable-stats.json to the same place as the
  // server-bundle.js. Thus, the __dirname of this code is where we can find loadable-stats.json.
  const statsFile = path.resolve(__dirname, 'loadable-stats.json');
  const extractor = new ChunkExtractor({ entrypoints: ['client-bundle'], statsFile });
  const { pathname } = railsContext;
  // For server-side rendering with @dr.pogodin/react-helmet, we pass a context object
  // to HelmetProvider to capture the helmet data per-request (thread-safe)
  const helmetContext = {};
  const componentHtml = renderToString(
    extractor.collectChunks(
      <HelmetProvider context={helmetContext}>
        <App {...props} path={pathname} />
      </HelmetProvider>,
    ),
  );
  const { helmet } = helmetContext;

  return {
    renderedHtml: {
      componentHtml,
      link: helmet?.link?.toString() || '',
      linkTags: extractor.getLinkTags(),
      styleTags: extractor.getStyleTags(),
      meta: helmet?.meta?.toString() || '',
      scriptTags: extractor.getScriptTags(),
      style: helmet?.style?.toString() || '',
      title: helmet?.title?.toString() || '',
    },
  };
};

export default loadableApp;
