'use client';

import path from 'path';
import React from 'react';
import { ChunkExtractor } from '@loadable/server';
import { renderToString } from 'react-dom/server';
import { Helmet, HelmetProvider } from '@dr.pogodin/react-helmet';

import LeakRepro from '../components/LeakRepro';

const LeakReproHashApp = (props, _railsContext) => {
  const statsFile = path.resolve(__dirname, 'loadable-stats.json');
  const extractor = new ChunkExtractor({ entrypoints: ['client-bundle'], statsFile });
  const helmetContext = {};
  const componentHtml = renderToString(
    extractor.collectChunks(
      <HelmetProvider context={helmetContext}>
        <Helmet>
          <title>Leak Repro — {props.items.length} Items</title>
        </Helmet>
        <LeakRepro {...props} />
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

export default LeakReproHashApp;
