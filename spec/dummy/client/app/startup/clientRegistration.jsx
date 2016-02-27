import ReactOnRails from 'react-relay-on-rails';

import HelloWorld from '../components/HelloWorld';
import HelloWorldWithLogAndThrow from '../components/HelloWorldWithLogAndThrow';
import HelloWorldES5 from '../components/HelloWorldES5';
import HelloWorldApp from './HelloWorldApp';
import Sample from '../components/Sample';
import SampleRoute from '../routes/SampleRoute';

import ReduxApp from './ClientReduxApp';
import ReduxSharedStoreApp from './ClientReduxSharedStoreApp';
import RouterApp from './ClientRouterApp';
import PureComponent from '../components/PureComponent';

import SharedReduxStore from '../stores/SharedReduxStore'

ReactOnRails.setOptions({
  traceTurbolinks: true
});

ReactOnRails.registerRoute({
  SampleRoute,
});
ReactOnRails.register({
  HelloWorld,
  Sample,
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
