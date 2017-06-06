import ReactOnRails from 'react-on-rails';

import App from './App';
import Index from './Index'

// This is how react_on_rails can see the your components and containers in the browser.

ReactOnRails.register({
  App,
	Index,
});
