import ReactOnRails from 'react-on-rails';

import HelloWorld from '../components/HelloWorld';
import HelloWorldWithLogAndThrow from '../components/HelloWorldWithLogAndThrow';
import HelloWorldES5 from '../components/HelloWorldES5';
import ReduxApp from './ClientReduxApp';
import HelloWorldApp from './HelloWorldApp';
import RouterApp from './ClientRouterApp';

ReactOnRails.registerComponent('HelloWorld', HelloWorld);
ReactOnRails.registerComponent('HelloWorldWithLogAndThrow', HelloWorldWithLogAndThrow);
ReactOnRails.registerComponent('HelloWorldES5', HelloWorldES5);
ReactOnRails.registerComponent('ReduxApp', ReduxApp);
ReactOnRails.registerComponent('HelloWorldApp', HelloWorldApp);
ReactOnRails.registerComponent('RouterApp', RouterApp);
