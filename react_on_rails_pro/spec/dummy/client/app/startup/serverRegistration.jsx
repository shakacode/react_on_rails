import 'babel-polyfill';
import 'es5-shim';
import ReactOnRails from 'react-on-rails';
import ReduxSharedStoreApp from './ServerReduxSharedStoreApp';
import SharedReduxStore from '../stores/SharedReduxStore';

ReactOnRails.register({
  ReduxSharedStoreApp,
});

ReactOnRails.registerStore({
  SharedReduxStore,
});
