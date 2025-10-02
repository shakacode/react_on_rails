import '../assets/styles/application.css';

import ReactOnRails from 'react-on-rails-pro';
import Turbolinks from 'turbolinks';
import SharedReduxStore from '../stores/SharedReduxStore';

const urlParams = new URLSearchParams(window.location.search);
const enableTurbolinks = urlParams.get('enableTurbolinks') === 'true';
if (enableTurbolinks) {
  Turbolinks.start();

  document.addEventListener('turbolinks:load', () => {
    console.log('Turbolinks loaded from client-bundle.js');
  });
}

ReactOnRails.setOptions({
  traceTurbolinks: true,
  turbo: enableTurbolinks,
});

ReactOnRails.registerStoreGenerators({
  SharedReduxStore,
});
