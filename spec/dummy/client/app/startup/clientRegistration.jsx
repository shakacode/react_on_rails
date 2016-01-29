import ReactOnRails from 'react-on-rails';

import HelloWorld from '../components/HelloWorld';
import HelloWorldWithLogAndThrow from '../components/HelloWorldWithLogAndThrow';
import HelloWorldES5 from '../components/HelloWorldES5';
import HelloWorldApp from './HelloWorldApp';

import ReduxApp from './ClientReduxApp';
import RouterApp from './ClientRouterApp';
import PureComponent from '../components/PureComponent';

ReactOnRails.setOptions({
  traceTurbolinks: true
});

ReactOnRails.register({
  HelloWorld,
  HelloWorldWithLogAndThrow,
  HelloWorldES5,
  ReduxApp,
  HelloWorldApp,
  RouterApp,
  PureComponent,
});
