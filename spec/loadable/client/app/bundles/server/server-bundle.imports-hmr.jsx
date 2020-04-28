// See spec/loadable/README.md for details regarding **.imports-X.** file extension & duplicate file structure.
import React from 'react';
import { renderToString } from 'react-dom/server';
import { Helmet } from 'react-helmet';

import App from '../foo/startup/App';

// Version of the consumer app to use without loadable components to enable HMR
const hmrApp = (props, railsContext) => {
  const componentHtml = renderToString(React.createElement(App, { ...props, railsContext }));
  const helmet = Helmet.renderStatic();

  return {
    renderedHtml: {
      componentHtml,
      link: helmet.link.toString(),
      meta: helmet.meta.toString(),
      style: helmet.style.toString(),
      title: helmet.title.toString(),
    },
  };
};

export default hmrApp;
