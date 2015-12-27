import ReactOnRails from 'react-on-rails';

import HelloWorld from '../components/HelloWorld';
import HelloWorldWithLogAndThrow from '../components/HelloWorldWithLogAndThrow';
import HelloWorldES5 from '../components/HelloWorldES5';
import ReduxApp from './ClientReduxApp';
import HelloWorldApp from './HelloWorldApp';
import RouterApp from './ClientRouterApp';

ReactOnRails.register('HelloWorld', HelloWorld);
ReactOnRails.register('HelloWorldWithLogAndThrow', HelloWorldWithLogAndThrow);
ReactOnRails.register('HelloWorldES5', HelloWorldES5);
ReactOnRails.register('ReduxApp', ReduxApp);
ReactOnRails.register('HelloWorldApp', HelloWorldApp);
ReactOnRails.register('RouterApp', RouterApp);
