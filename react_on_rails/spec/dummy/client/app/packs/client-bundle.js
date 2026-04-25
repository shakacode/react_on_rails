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

if (!ReactOnRails[STRICT_MODE_PATCHED]) {
  const originalRegister = ReactOnRails.register.bind(ReactOnRails);

  // Covers this bundle and inline ERB register calls, which run after the bundle has loaded.
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
