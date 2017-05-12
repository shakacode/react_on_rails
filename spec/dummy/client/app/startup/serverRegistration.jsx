import 'babel-polyfill';
import 'es5-shim';
import ReactOnRails from 'react-on-rails';
import ReduxSharedStoreApp from './ServerReduxSharedStoreApp';
import ComponentWithLodashApp from './ComponentWithLodashApp';
import SharedReduxStore from '../stores/SharedReduxStore';

ReactOnRails.register({
  ReduxSharedStoreApp,
  ComponentWithLodashApp,
});

ReactOnRails.registerStore({
  SharedReduxStore,
});
