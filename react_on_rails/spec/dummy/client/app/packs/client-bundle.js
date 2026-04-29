import 'core-js/stable';
import 'regenerator-runtime/runtime';
import 'jquery';
import 'jquery-ujs';
import '@hotwired/turbo-rails';

import ReactOnRails from 'react-on-rails/client';

import HelloTurboStream from '../startup/HelloTurboStream';
import ManualRenderComponent from '../startup/ManualRenderComponent';
import SharedReduxStore from '../stores/SharedReduxStore';
import { wrapRegisteredComponentsWithStrictMode } from '../strictModeSupport';

const STRICT_MODE_PATCHED = '__reactOnRailsDummyStrictModePatched';

// Scope: this patch only affects `ReactOnRails.register` calls that share this bundle's module
// instance (this pack and inline ERB views that run after it). Separate entry-point packs that
// import `react-on-rails/client` independently get their own unpatched module and would skip
// StrictMode wrapping.
if (!ReactOnRails[STRICT_MODE_PATCHED]) {
  const originalRegister = ReactOnRails.register.bind(ReactOnRails);

  ReactOnRails.register = (components) =>
    originalRegister(wrapRegisteredComponentsWithStrictMode(components));
  Object.defineProperty(ReactOnRails, STRICT_MODE_PATCHED, { value: true });
}

ReactOnRails.setOptions({
  traceTurbolinks: true,
  turbo: true,
});

ReactOnRails.register({
  HelloTurboStream,
  ManualRenderComponent,
});

ReactOnRails.registerStore({
  SharedReduxStore,
});
