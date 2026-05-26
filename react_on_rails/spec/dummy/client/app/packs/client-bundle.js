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

const useStrictMode = process.env.NODE_ENV !== 'production';

const STRICT_MODE_PATCHED = '__reactOnRailsDummyStrictModePatched';

// Scope: this patch only affects `ReactOnRails.register` calls that share this bundle's
// `react-on-rails/client` module instance. Coverage today:
//   - This pack and its imports (HelloTurboStream, ManualRenderComponent, SharedReduxStore).
//   - The auto-generated `packs/generated/*.js` entries — they share this `ReactOnRails` instance
//     because shakapacker's webpack build produces one runtime per compilation, and they run
//     after `client-bundle.js` on every page that loads them.
//   - Inline ERB views that call `ReactOnRails.register` after this pack has run.
//   - Manual-render trees in `startup/` and `app-react16/startup/` already wrap with
//     `wrapElementInStrictMode` directly (they don't need this `register` patch).
//
// What's NOT covered: any future pack that imports `react-on-rails/client` from a separate
// webpack compilation (e.g., a standalone bundle config) would get its own unpatched module
// instance. When adding a pack like that, either fold it into this compilation or duplicate
// this `STRICT_MODE_PATCHED` block at the top of the new pack before any `register` calls.
if (useStrictMode && !ReactOnRails[STRICT_MODE_PATCHED]) {
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
