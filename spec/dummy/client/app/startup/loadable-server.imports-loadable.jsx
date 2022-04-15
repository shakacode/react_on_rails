import React from 'react';
import { ChunkExtractor } from '@loadable/server';
import { renderToString } from 'react-dom/server';
import { Helmet } from 'react-helmet';

import App from './LoadableApp';

const loadableApp = (props, _railsContext) => {
  const path = require('path');

  // Note, React on Rails Pro copies the loadable-stats.json to the same place as the
  // server-bundle.js. Thus, the __dirname of this code is where we can find loadable-stats.json.
  const statsFile = path.resolve(__dirname, 'loadable-stats.json');
  const extractor = new ChunkExtractor({ entrypoints: ['client-bundle'], statsFile });
  const componentHtml = renderToString(extractor.collectChunks(<App {...props} />));
  const helmet = Helmet.renderStatic();

  return {
    renderedHtml: {
      componentHtml,
      link: helmet.link.toString(),
      linkTags: extractor.getLinkTags(),
      meta: helmet.meta.toString(),
      scriptTags: extractor.getScriptTags(),
      style: helmet.style.toString(),
      title: helmet.title.toString(),
    },
  };
};

export default loadableApp;
