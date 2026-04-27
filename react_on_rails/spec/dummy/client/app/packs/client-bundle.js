import 'core-js/stable';
import 'regenerator-runtime/runtime';
import 'jquery';
import 'jquery-ujs';
import '@hotwired/turbo-rails';

import ReactOnRails from 'react-on-rails/client';

import HelloTurboStream from '../startup/HelloTurboStream';
import ManualRenderComponent from '../startup/ManualRenderComponent';
import SharedReduxStore from '../stores/SharedReduxStore';

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
