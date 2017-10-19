import 'babel-polyfill';
import 'es5-shim';

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
import BrokenApp from './BrokenApp';

// Example of React + Redux
import ReduxApp from './ServerReduxApp';

// Example of 2 React components sharing the same store
import ReduxSharedStoreApp from './ServerReduxSharedStoreApp';

// Example of React Router with Server Rendering
import RouterApp from './ServerRouterApp';

import PureComponent from '../components/PureComponent';
import CssModulesImagesFontsExample from '../components/CssModulesImagesFontsExample';

import SharedReduxStore from '../stores/SharedReduxStore';

// Deferred render on the client side w/ server render
import DeferredRenderApp from './DeferredRenderAppServer';

// Deferred render on the client side w/ server render
import RenderedHtml from './ServerRenderedHtml';

// Deferred render on the client side w/ server render with additional HTML strings:
import ReactHelmetApp from './ReactHelmetServerApp';

// Demonstrate using Images
import ImageExample from '../components/ImageExample';

ReactOnRails.register({
  BrokenApp,
  HelloWorld,
  HelloWorldWithLogAndThrow,
  HelloWorldES5,
  ReduxApp,
  ReduxSharedStoreApp,
  HelloWorldApp,
  RouterApp,
  HelloString,
  PureComponent,
  CssModulesImagesFontsExample,
  DeferredRenderApp,
  RenderedHtml,
  ReactHelmetApp,
  ImageExample,
});

ReactOnRails.registerStore({
  SharedReduxStore,
});
