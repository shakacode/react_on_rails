import React from 'react';
import { hydrateRoot } from 'react-dom/client';

import { loadableReady } from '@loadable/component';

import ClientApp from './LoadableApp';

const App = (props, railsContext, domNodeId) => {
  loadableReady(() => {
    const el = document.getElementById(domNodeId);
    hydrateRoot(el, React.createElement(ClientApp, { ...props, path: railsContext.pathname }));
  });
};

export default App;
