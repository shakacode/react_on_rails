// import statement added by react_on_rails:generate_packs rake task
import '../generated/server-bundle-generated.js'; // eslint-disable-line import/extensions
// Shows the mapping from the exported object to the name used by the server rendering.
import ReactOnRails from 'react-on-rails';
// Example of server rendering with no React
import HelloString from '../non_react/HelloString';
import HydrationSchedulingProbe from '../startup/HydrationSchedulingProbe';
import StreamingHydrationDemo from '../startup/StreamingHydrationDemo';

import SharedReduxStore from '../stores/SharedReduxStore';

ReactOnRails.register({
  HelloString,
  HydrationSchedulingProbe,
  StreamingHydrationDemo,
});

ReactOnRails.registerStoreGenerators({
  SharedReduxStore,
});
