import React from 'react';
import { Provider } from 'react-redux';
import ReactOnRails from 'react-on-rails/client';

import HelloWorldContainer from '../components/HelloWorldContainer';
import { wrapElementInStrictMode } from '../strictModeSupport';
import type { ReduxAppStore } from '../store/reduxTypes';
import { hydrateOrRender } from './domRenderers';

export default function ReduxSharedStoreApp(
  props: Record<string, unknown>,
  _railsContext: unknown,
  domNodeId: string,
): void {
  const render = hydrateOrRender(Boolean(props.prerender));
  const store = ReactOnRails.getStore('SharedReduxStore') as ReduxAppStore;

  const renderApp = (Component: typeof HelloWorldContainer) => {
    const element = wrapElementInStrictMode(
      <Provider store={store}>
        <Component />
      </Provider>,
    );
    const domNode = document.getElementById(domNodeId);

    if (!domNode) {
      throw new Error(`Could not find DOM node with id '${domNodeId}' for ReduxSharedStoreApp.`);
    }

    render(domNode, element);
  };

  renderApp(HelloWorldContainer);

  if (module.hot) {
    module.hot.accept(['../components/HelloWorldContainer'], () => {
      renderApp(HelloWorldContainer);
    });
  }
}
