import React from 'react';
import ReactDOM from 'react-dom/client';

import { loadableReady } from '@loadable/component';

import ClientApp from './LoadableApp';

const App = (props, _railsContext, domNodeId) => {
  loadableReady(() => {
    const el = document.getElementById(domNodeId);
    ReactDOM.hydrateRoot(el, React.createElement(ClientApp, { ...props }));
  });
};

export default App;
