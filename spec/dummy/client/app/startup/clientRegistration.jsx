import 'babel-polyfill';
import 'es5-shim';
import ReactOnRails from 'react-on-rails';
import ReduxSharedStoreApp from './ClientReduxSharedStoreApp';
import SharedReduxStore from '../stores/SharedReduxStore';

ReactOnRails.setOptions({
  traceTurbolinks: true,
});

ReactOnRails.register({
  ReduxSharedStoreApp,
});

ReactOnRails.registerStore({
  SharedReduxStore,
});
