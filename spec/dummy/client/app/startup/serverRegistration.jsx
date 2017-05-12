import 'babel-polyfill';
import 'es5-shim';
import ReactOnRails from 'react-on-rails';
import ReduxSharedStoreApp from './ServerReduxSharedStoreApp';
import SharedReduxStore from '../stores/SharedReduxStore';

// TODO: Move this to additional example for checking lodash requiring:
import fp from 'lodash/fp'

//console.log(fp);

ReactOnRails.register({
  ReduxSharedStoreApp,
});

ReactOnRails.registerStore({
  SharedReduxStore,
});
