// import statement added by react_on_rails:generate_packs rake task
import './server-bundle-generated.js';
// Shows the mapping from the exported object to the name used by the server rendering.
import ReactOnRails from 'react-on-rails';
// Example of server rendering with no React
import HelloString from '../non_react/HelloString';

import SharedReduxStore from '../stores/SharedReduxStore';

ReactOnRails.register({
  HelloString,
});

ReactOnRails.registerStore({
  SharedReduxStore,
});
