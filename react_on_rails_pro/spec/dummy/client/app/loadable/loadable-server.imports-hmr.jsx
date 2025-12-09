import React from 'react';
import { renderToString } from 'react-dom/server';
import { HelmetProvider } from '@dr.pogodin/react-helmet';

import App from './LoadableApp';

// Version of the consumer app to use without loadable components to enable HMR
const hmrApp = (props, railsContext) => {
  // For server-side rendering with @dr.pogodin/react-helmet, we pass a context object
  // to HelmetProvider to capture the helmet data per-request (thread-safe)
  const helmetContext = {};
  const componentHtml = renderToString(
    <HelmetProvider context={helmetContext}>
      {React.createElement(App, { ...props, path: railsContext.pathname })}
    </HelmetProvider>,
  );
  const { helmet } = helmetContext;

  return {
    renderedHtml: {
      componentHtml,
      link: helmet?.link?.toString() || '',
      meta: helmet?.meta?.toString() || '',
      style: helmet?.style?.toString() || '',
      title: helmet?.title?.toString() || '',
    },
  };
};

export default hmrApp;
