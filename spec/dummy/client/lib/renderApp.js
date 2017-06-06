import React from 'react';
import { render } from 'react-dom';
import { AppContainer } from 'react-hot-loader';

import consoleErrorReporter from 'lib/consoleErrorReporter';

const renderApp = (Komponent, props, railsContext, domNodeId) => {
  const element = (
    <AppContainer errorReporter={consoleErrorReporter}>
      <Komponent {...props} railsContext={railsContext} />
    </AppContainer>
  );
  render(element, document.getElementById(domNodeId));
};

export default renderApp;
