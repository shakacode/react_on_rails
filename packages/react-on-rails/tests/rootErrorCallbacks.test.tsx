/**
 * @jest-environment jsdom
 */

/**
 * Integration tests for ReactOnRails root error callbacks (issue #3892) using the REAL react-dom
 * runtime (React 19 in this workspace): a forced hydration mismatch must invoke the user's
 * onRecoverableError, and render-path errors must reach onUncaughtError/onCaughtError — all with
 * the React on Rails-enriched context (component name + dom id).
 */

import * as React from 'react';
import { act } from 'react-dom/test-utils';
import { renderComponent } from '../src/ClientRenderer.ts';
import ComponentRegistry from '../src/ComponentRegistry.ts';
import { setRootErrorHandlers, resetRootErrorHandlers } from '../src/rootErrorHandlers.ts';
import { resetRailsContext } from '../src/context.ts';
import { supportsReact19RootErrorCallbacks } from '../src/reactApis.cts';

declare global {
  // eslint-disable-next-line no-var, vars-on-top
  var IS_REACT_ACT_ENVIRONMENT: boolean | undefined;
}

globalThis.IS_REACT_ACT_ENVIRONMENT = true;

const react19It = supportsReact19RootErrorCallbacks ? it : it.skip;

const setupRailsContext = (railsEnv = 'test'): void => {
  const railsContextElement = document.createElement('div');
  railsContextElement.id = 'js-react-on-rails-context';
  railsContextElement.textContent = JSON.stringify({
    railsEnv,
    inMailer: false,
    i18nLocale: 'en',
    i18nDefaultLocale: 'en',
    rorVersion: '17.0.0',
    rorPro: false,
    href: 'http://localhost:3000',
    location: 'http://localhost:3000',
    scheme: 'http',
    host: 'localhost',
    port: 3000,
    pathname: '/',
    search: null,
    httpAcceptLanguage: 'en',
    serverSide: false,
    componentRegistryTimeout: 0,
  });
  document.body.appendChild(railsContextElement);
};

const setupComponentDom = (componentName: string, domId: string, serverHtml = ''): HTMLElement => {
  const componentElement = document.createElement('div');
  componentElement.className = 'js-react-on-rails-component';
  componentElement.setAttribute('data-component-name', componentName);
  componentElement.setAttribute('data-dom-id', domId);
  componentElement.textContent = JSON.stringify({});
  document.body.appendChild(componentElement);

  const targetNode = document.createElement('div');
  targetNode.id = domId;
  if (serverHtml) {
    targetNode.innerHTML = serverHtml;
  }
  document.body.appendChild(targetNode);
  return targetNode;
};

describe('root error callbacks with real react-dom (React 19)', () => {
  beforeEach(() => {
    ComponentRegistry.clear();
    resetRootErrorHandlers();
    resetRailsContext();
    document.body.innerHTML = '';
    jest.clearAllMocks();
  });

  afterEach(() => {
    ComponentRegistry.clear();
    resetRootErrorHandlers();
    resetRailsContext();
  });

  it('invokes the user onRecoverableError with enriched context on a forced hydration mismatch', async () => {
    setupRailsContext();
    const onRecoverableError = jest.fn();
    setRootErrorHandlers({ onRecoverableError });

    const MismatchComponent: React.FC = () => React.createElement('div', null, 'client text');
    ComponentRegistry.register({ MismatchComponent });
    // Server-rendered HTML that deliberately differs from the client render output.
    const targetNode = setupComponentDom('MismatchComponent', 'mismatch-dom-id', '<div>server text</div>');

    await act(async () => {
      renderComponent('mismatch-dom-id');
    });

    expect(onRecoverableError).toHaveBeenCalled();
    const [error, , context] = onRecoverableError.mock.calls[0] as [unknown, unknown, unknown];
    expect(error).toBeTruthy();
    expect(context).toEqual({ componentName: 'MismatchComponent', domNodeId: 'mismatch-dom-id' });
    // React recovered by re-rendering on the client.
    expect(targetNode.textContent).toBe('client text');
  });

  it('logs the branded dev-mode hydration message with the guide link in development', async () => {
    setupRailsContext('development');

    const MismatchComponent: React.FC = () => React.createElement('div', null, 'client text');
    ComponentRegistry.register({ MismatchComponent });
    setupComponentDom('MismatchComponent', 'dev-mismatch-dom-id', '<div>server text</div>');

    await act(async () => {
      renderComponent('dev-mismatch-dom-id');
    });

    const consoleErrorCalls = (console.error as jest.Mock).mock.calls;
    const brandedCall = consoleErrorCalls.find(
      (call) =>
        typeof call[0] === 'string' &&
        call[0].includes('[ReactOnRails] Recoverable hydration error in component "MismatchComponent"'),
    );
    expect(brandedCall).toBeDefined();
    expect(brandedCall?.[0]).toContain('dom id: "dev-mismatch-dom-id"');
    expect(brandedCall?.[0]).toContain(
      'https://reactonrails.com/docs/building-features/debugging-hydration-mismatches',
    );
  });

  react19It(
    'invokes the user onUncaughtError with enriched context on the client-render (createRoot) path',
    async () => {
      setupRailsContext();
      const onUncaughtError = jest.fn();
      setRootErrorHandlers({ onUncaughtError });

      const renderError = new Error('deliberate render error');
      const ThrowingComponent: React.FC = () => {
        throw renderError;
      };
      ComponentRegistry.register({ ThrowingComponent });
      // No server HTML: this exercises the createRoot (client-render) path.
      setupComponentDom('ThrowingComponent', 'throwing-dom-id');

      // Under `act`, React intentionally rethrows uncaught render errors instead of routing them to
      // the root's onUncaughtError option, so this test renders without act and flushes React's
      // scheduled work with a macrotask instead.
      globalThis.IS_REACT_ACT_ENVIRONMENT = false;
      try {
        renderComponent('throwing-dom-id');
        await new Promise((resolve) => {
          setTimeout(resolve, 0);
        });
      } finally {
        globalThis.IS_REACT_ACT_ENVIRONMENT = true;
      }

      expect(onUncaughtError).toHaveBeenCalled();
      const [error, , context] = onUncaughtError.mock.calls[0] as [unknown, unknown, unknown];
      expect(error).toBe(renderError);
      expect(context).toEqual({ componentName: 'ThrowingComponent', domNodeId: 'throwing-dom-id' });
    },
  );

  react19It(
    'invokes the user onCaughtError with enriched context when an error boundary catches',
    async () => {
      setupRailsContext();
      const onCaughtError = jest.fn();
      setRootErrorHandlers({ onCaughtError });

      const boundaryError = new Error('caught by boundary');
      const ThrowingChild: React.FC = () => {
        throw boundaryError;
      };

      class Boundary extends React.Component<React.PropsWithChildren, { hasError: boolean }> {
        constructor(props: React.PropsWithChildren) {
          super(props);
          this.state = { hasError: false };
        }

        static getDerivedStateFromError() {
          return { hasError: true };
        }

        render() {
          const { hasError } = this.state;
          const { children } = this.props;
          return hasError ? React.createElement('div', null, 'fallback') : children;
        }
      }

      const BoundaryComponent: React.FC = () =>
        React.createElement(Boundary, null, React.createElement(ThrowingChild));
      ComponentRegistry.register({ BoundaryComponent });
      setupComponentDom('BoundaryComponent', 'boundary-dom-id');

      await act(async () => {
        renderComponent('boundary-dom-id');
      });

      expect(onCaughtError).toHaveBeenCalled();
      const [error, , context] = onCaughtError.mock.calls[0] as [unknown, unknown, unknown];
      expect(error).toBe(boundaryError);
      expect(context).toEqual({ componentName: 'BoundaryComponent', domNodeId: 'boundary-dom-id' });
    },
  );
});
