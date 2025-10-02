// import statement added by react_on_rails:generate_packs rake task
import './../generated/server-bundle-generated.js';
// Shows the mapping from the exported object to the name used by the server rendering.
import ReactOnRails from 'react-on-rails-pro';

// Example of server rendering with no React
import HelloString from '../non_react/HelloString';

import SharedReduxStore from '../stores/SharedReduxStore';

// This section is used exclusively for testing purposes. It allows us to create a new React component and register it within the RSC (React Server Components) bundle.
if (process.env.NODE_ENV === 'test') {
  globalThis.React = require('react');
}

ReactOnRails.register({
  HelloString,
});

ReactOnRails.registerStore({
  SharedReduxStore,
});
