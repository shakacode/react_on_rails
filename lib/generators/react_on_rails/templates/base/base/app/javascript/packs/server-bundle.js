import ReactOnRails from 'react-on-rails/server';

import HelloWorld from '../bundles/HelloWorld/components/HelloWorldServer';

// This is how react_on_rails can see the HelloWorld in the browser.
ReactOnRails.register({
  HelloWorld,
});
