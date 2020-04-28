// See spec/loadable/README.md for details regarding **.imports-X.** file extension & duplicate file structure.
import React from 'react';
import ReactDOM from 'react-dom';

import { loadableReady } from '@loadable/component';

import ClientApp from './App';

const App = (props, _railsContext, domNodeId) => {
  loadableReady(() => {
    ReactDOM.hydrate(React.createElement(ClientApp, { ...props }), document.getElementById(domNodeId));
  });
};

export default App;
