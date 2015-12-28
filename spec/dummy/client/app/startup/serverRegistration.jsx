// Shows the mapping from the exported object to the name used by the server rendering.
import ReactOnRails from 'react-on-rails';

// Example of server rendering with no React
import HelloString from '../non_react/HelloString';

// React components
import HelloWorld from '../components/HelloWorld';
import HelloWorldES5 from '../components/HelloWorldES5';
import HelloWorldWithLogAndThrow from '../components/HelloWorldWithLogAndThrow';

// Generator function
import HelloWorldApp from './HelloWorldApp';

// Example of React + Redux
import ReduxApp from './ServerReduxApp';

// Example of React Router with Server Rendering
import RouterApp from './ServerRouterApp';

import PureComponent from '../components/PureComponent';

ReactOnRails.register({
  HelloWorld,
  HelloWorldWithLogAndThrow,
  HelloWorldES5,
  ReduxApp,
  HelloWorldApp,
  RouterApp,
  HelloString,
  PureComponent,
});
