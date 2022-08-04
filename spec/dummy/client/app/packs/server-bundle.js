// Shows the mapping from the exported object to the name used by the server rendering.
import ReactOnRails from 'react-on-rails';

// Example of server rendering with no React
import HelloString from '../non_react/HelloString';

// React components
import HelloWorld from '../components/HelloWorld';

import HelloWorldES5 from '../components/HelloWorldES5';
import HelloWorldRehydratable from '../components/HelloWorldRehydratable';
import HelloWorldWithLogAndThrow from '../components/HelloWorldWithLogAndThrow';
import HelloWorldHooks from '../components/HelloWorldHooks';
import HelloWorldHooksContext from '../components/HelloWorldHooksContext';

// Generator function
import HelloWorldApp from '../startup/HelloWorldApp';
import BrokenApp from '../startup/BrokenApp';

// Example of React + Redux
import ReduxApp from '../startup/ServerReduxApp';

// Example of 2 React components sharing the same store
import ReduxSharedStoreApp from '../startup/ServerReduxSharedStoreApp';

// Example of React Router with Server Rendering
import RouterApp from '../startup/ServerRouterApp';

import PureComponent from '../components/PureComponent';
import CssModulesImagesFontsExample from '../components/CssModulesImagesFontsExample';

import SharedReduxStore from '../stores/SharedReduxStore';

// Deferred render on the client side w/ server render
import ManualRenderApp from '../startup/ManualRenderAppRenderer';

// Deferred render on the client side w/ server render
import RenderedHtml from '../startup/ServerRenderedHtml';

// Deferred render on the client side w/ server render with additional HTML strings:
import ReactHelmetApp from '../startup/ReactHelmetServerApp';

// Demonstrate using Images
import ImageExample from '../components/ImageExample';

import CacheDisabled from '../components/CacheDisabled';

import SetTimeoutLoggingApp from '../startup/SetTimeoutServerApp';

import Loadable from '../startup/loadable-server.imports-loadable';

ReactOnRails.register({
  BrokenApp,
  HelloWorld,
  HelloWorldWithLogAndThrow,
  HelloWorldES5,
  HelloWorldRehydratable,
  HelloWorldHooksContext,
  HelloWorldHooks,
  ReduxApp,
  ReduxSharedStoreApp,
  HelloWorldApp,
  ManualRenderApp,
  CacheDisabled,
  RouterApp,
  HelloString,
  PureComponent,
  CssModulesImagesFontsExample,
  RenderedHtml,
  ReactHelmetApp,
  ImageExample,
  SetTimeoutLoggingApp,
  Loadable,
});

ReactOnRails.registerStore({
  SharedReduxStore,
});
