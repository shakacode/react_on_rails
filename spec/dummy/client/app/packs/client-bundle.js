import 'core-js/stable';
import 'regenerator-runtime/runtime';
import 'jquery';
import 'jquery-ujs';
import '@hotwired/turbo-rails';

import ReactOnRails from 'react-on-rails';

import SharedReduxStore from '../stores/SharedReduxStore';

import HelloTurboStream from '../startup/HelloTurboStream';

ReactOnRails.setOptions({
  traceTurbolinks: true,
  turbo: true
});

ReactOnRails.register({
  HelloTurboStream
});

ReactOnRails.registerStore({
  SharedReduxStore,
});
