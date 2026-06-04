import React, { type ReactNode } from 'react';
import ReactDOMClient from 'react-dom/client';
import { Provider } from 'react-redux';
import ReactOnRails from 'react-on-rails/client';

import HelloWorldContainer from '../components/HelloWorldContainer';
import { wrapElementInStrictMode } from '../strictModeSupport';
import type { ReduxAppStore } from '../store/reduxTypes';

declare const module: {
  hot?: {
    accept(dependencies: string[], callback: () => void): void;
  };
};

type DomRenderer = (domNode: Element, element: ReactNode) => void;
const hydrateOrRender = (shouldHydrate: boolean): DomRenderer =>
  shouldHydrate
    ? (domNode, element) => {
        ReactDOMClient.hydrateRoot(domNode, element);
      }
    : (domNode, element) => {
        const root = ReactDOMClient.createRoot(domNode);
        root.render(element);
      };

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
