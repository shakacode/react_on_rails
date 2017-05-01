import 'babel-polyfill';
import 'es5-shim';
import ReactOnRails from 'react-on-rails';
import HelloWorld from '../components/HelloWorld';
import SharedReduxStore from '../stores/SharedReduxStore';

ReactOnRails.register({
  HelloWorld,
});

ReactOnRails.registerStore({
  SharedReduxStore,
});
