import ReactOnRails from 'react-on-rails';

import HelloWorld from '../components/HelloWorld';
import HelloWorldWithLogAndThrow from '../components/HelloWorldWithLogAndThrow';
import HelloWorldES5 from '../components/HelloWorldES5';
import HelloWorldApp from './HelloWorldApp';

import ReduxApp from './ClientReduxApp';
import ReduxSharedStoreApp from './ClientReduxSharedStoreApp';
import RouterApp from './ClientRouterApp';
import PureComponent from '../components/PureComponent';

import SharedReduxStore from '../stores/SharedReduxStore'

ReactOnRails.setOptions({
  traceTurbolinks: true
});

ReactOnRails.register({
  HelloWorld,
  HelloWorldWithLogAndThrow,
  HelloWorldES5,
  ReduxApp,
  ReduxSharedStoreApp,
  HelloWorldApp,
  RouterApp,
  PureComponent,
});

ReactOnRails.registerStore({
  SharedReduxStore
});
