import React from 'react';
import { hydrateRoot } from 'react-dom/client';

import { loadableReady } from '@loadable/component';
import { HelmetProvider } from '@dr.pogodin/react-helmet';

import ClientApp from './LoadableApp';

const App = (props, railsContext, domNodeId) => {
  loadableReady(() => {
    const el = document.getElementById(domNodeId);
    hydrateRoot(
      el,
      <HelmetProvider>
        {React.createElement(ClientApp, { ...props, path: railsContext.pathname })}
      </HelmetProvider>,
    );
  });
};

export default App;
