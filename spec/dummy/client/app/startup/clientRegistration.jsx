import ReactOnRails from 'react-on-rails';

import registration from './registration';

import HelloWorld from '../components/HelloWorld';
import HelloWorldWithLogAndThrow from '../components/HelloWorldWithLogAndThrow';
import HelloWorldES5 from '../components/HelloWorldES5';
import HelloWorldApp from './HelloWorldApp';

import ReduxApp from './ClientReduxApp';
import RouterApp from './ClientRouterApp';
import HelloString from '../non_react/HelloString';

ReactOnRails.register({
  HelloWorld,
  HelloWorldWithLogAndThrow,
  HelloWorldES5,
  ReduxApp,
  HelloWorldApp,
  RouterApp,
});
