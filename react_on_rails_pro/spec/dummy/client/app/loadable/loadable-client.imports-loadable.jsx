import React from 'react';
import { hydrateRoot } from 'react-dom/client';

import { loadableReady } from '@loadable/component';
import { HelmetProvider } from '@dr.pogodin/react-helmet';

import ClientApp from './LoadableApp';
import { wrapElementInStrictMode } from '../strictModeSupport';

const App = (props, railsContext, domNodeId) =>
  // loadableReady resolves once the split chunks are present, then we hydrate. Returning the promise
  // (which resolves to a teardown wrapper) lets React on Rails unmount this root on Turbo/Turbolinks
  // navigation or same-id node replacement instead of leaking it. The callback form would discard it.
  loadableReady().then(() => {
    const el = document.getElementById(domNodeId);
    if (!el) return undefined; // Navigation may remove the node before chunks resolve.

    const reactElement = wrapElementInStrictMode(
      <HelmetProvider>
        {React.createElement(ClientApp, { ...props, path: railsContext.pathname })}
      </HelmetProvider>,
    );
    const root = hydrateRoot(el, reactElement);
    return { teardown: () => root.unmount() };
  });

export default App;
