import React from 'react';
import { hydrateRoot } from 'react-dom/client';

import { loadableReady } from '@loadable/component';
import { HelmetProvider } from '@dr.pogodin/react-helmet';

import ClientApp from './LoadableApp';
import { wrapElementInStrictMode } from '../strictModeSupport';

const App = (props, railsContext, domNodeId) => {
  loadableReady(() => {
    const el = document.getElementById(domNodeId);
    const reactElement = wrapElementInStrictMode(
      <HelmetProvider>
        {React.createElement(ClientApp, { ...props, path: railsContext.pathname })}
      </HelmetProvider>,
    );
    hydrateRoot(el, reactElement);
  });
};

export default App;
