import 'core-js/stable';
import 'regenerator-runtime/runtime';
import 'jquery';
import 'jquery-ujs';
import '@hotwired/turbo-rails';

import ReactOnRails from 'react-on-rails/client';
import { supportsReact19RootErrorCallbacks } from 'react-on-rails/reactApis';

import HelloTurboStream from '../startup/HelloTurboStream';
import HydrationSchedulingProbe from '../startup/HydrationSchedulingProbe';
import ManualRenderComponent from '../startup/ManualRenderComponent';
import StreamingHydrationDemo from '../startup/StreamingHydrationDemo';
import SharedReduxStore from '../stores/SharedReduxStore';
import { wrapRegisteredComponentsWithStrictMode } from '../strictModeSupport';

const useStrictMode = process.env.NODE_ENV !== 'production';

const STRICT_MODE_PATCHED = '__reactOnRailsDummyStrictModePatched';

const reactOnRailsWithStrictModeFlag = ReactOnRails as typeof ReactOnRails &
  Partial<Record<typeof STRICT_MODE_PATCHED, true>>;

// Scope: this patch only affects `ReactOnRails.register` calls that share this bundle's
// `react-on-rails/client` module instance. Coverage today:
//   - This pack and its imports (HelloTurboStream, ManualRenderComponent, SharedReduxStore).
//   - The auto-generated `packs/generated/*.js` entries — they share this `ReactOnRails` instance
//     because shakapacker's webpack build produces one runtime per compilation, and they run
//     after the `client-bundle` pack on every page that loads them.
//   - Inline ERB views that call `ReactOnRails.register` after this pack has run.
//   - Manual-render trees in `startup/` and `app-react16/startup/` already wrap with
//     `wrapElementInStrictMode` directly (they don't need this `register` patch).
//
// What's NOT covered: any future pack that imports `react-on-rails/client` from a separate
// webpack compilation (e.g., a standalone bundle config) would get its own unpatched module
// instance. When adding a pack like that, either fold it into this compilation or duplicate
// this `STRICT_MODE_PATCHED` block at the top of the new pack before any `register` calls.
if (useStrictMode && !reactOnRailsWithStrictModeFlag[STRICT_MODE_PATCHED]) {
  const originalRegister = ReactOnRails.register.bind(ReactOnRails);

  ReactOnRails.register = (components) =>
    originalRegister(wrapRegisteredComponentsWithStrictMode(components));
  Object.defineProperty(reactOnRailsWithStrictModeFlag, STRICT_MODE_PATCHED, { value: true });
}

// Issue #3892: record React root error callback invocations on `window` so Playwright e2e tests
// (e2e/playwright/e2e/react_on_rails/root_error_callbacks.spec.js) can assert that the callbacks
// fire for client-rendered and server-rendered+hydrated components. The handlers also mirror the
// error to console.error so default error visibility is preserved (registering a callback
// replaces React's own default reporting for that callback).
type RootErrorCallbackEvent = {
  kind: 'recoverable' | 'caught' | 'uncaught';
  message: string;
  componentName?: string;
  domNodeId?: string;
};

declare global {
  interface Window {
    __ROOT_ERROR_CALLBACK_EVENTS__?: RootErrorCallbackEvent[];
    __ROOT_ERROR_CALLBACK_SUPPORTS_REACT19__?: boolean;
  }
}

const recordRootErrorEvent =
  (kind: RootErrorCallbackEvent['kind']) =>
  (error: unknown, _errorInfo: unknown, context: { componentName?: string; domNodeId?: string }) => {
    /* eslint-disable no-underscore-dangle -- double-underscore marks the test-only window global */
    window.__ROOT_ERROR_CALLBACK_EVENTS__ ||= [];
    window.__ROOT_ERROR_CALLBACK_EVENTS__.push({
      kind,
      message: error instanceof Error ? error.message : String(error),
      componentName: context.componentName,
      domNodeId: context.domNodeId,
    });
    /* eslint-enable no-underscore-dangle */
    console.error(`[dummy] rootErrorHandlers ${kind} error callback fired:`, error);
  };

/* eslint-disable no-underscore-dangle -- double-underscore marks the test-only window global */
window.__ROOT_ERROR_CALLBACK_SUPPORTS_REACT19__ = supportsReact19RootErrorCallbacks;
/* eslint-enable no-underscore-dangle */

const rootErrorHandlers = {
  onRecoverableError: recordRootErrorEvent('recoverable'),
  ...(supportsReact19RootErrorCallbacks
    ? {
        onCaughtError: recordRootErrorEvent('caught'),
        onUncaughtError: recordRootErrorEvent('uncaught'),
      }
    : {}),
};

ReactOnRails.setOptions({
  traceTurbolinks: true,
  turbo: true,
  rootErrorHandlers,
});

ReactOnRails.register({
  HelloTurboStream,
  HydrationSchedulingProbe,
  ManualRenderComponent,
  StreamingHydrationDemo,
});

ReactOnRails.registerStoreGenerators({
  SharedReduxStore,
});
