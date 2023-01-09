import 'core-js/stable';
import 'regenerator-runtime/runtime';
import 'jquery';
import 'jquery-ujs';

import ReactOnRails from 'react-on-rails';

import SharedReduxStore from '../stores/SharedReduxStore';

ReactOnRails.setOptions({
  traceTurbolinks: true,
});

ReactOnRails.registerStore({
  SharedReduxStore,
});
