// Shows the mapping from the exported object to the name used by the server rendering.
import ReactOnRails from 'react-on-rails';

// Example of server rendering with no React
import HelloString from '../non_react/HelloString';

// React ror-auto-load-components
import HelloWorld from '../ror-auto-load-components/HelloWorld';

import HelloWorldES5 from '../ror-auto-load-components/HelloWorldES5';
import HelloWorldRehydratable from '../ror-auto-load-components/HelloWorldRehydratable';
import HelloWorldWithLogAndThrow from '../ror-auto-load-components/HelloWorldWithLogAndThrow';
import HelloWorldHooks from '../ror-auto-load-components/HelloWorldHooks';
import HelloWorldHooksContext from '../ror-auto-load-components/HelloWorldHooksContext';

// Generator function
import HelloWorldApp from '../ror-auto-load-components/HelloWorldApp';
import BrokenApp from '../ror-auto-load-components/BrokenApp';

// Example of React + Redux
import ReduxApp from '../ror-auto-load-components/ReduxApp.server';

// Example of 2 React ror-auto-load-components sharing the same store
import ReduxSharedStoreApp from '../ror-auto-load-components/ReduxSharedStoreApp.server';

// Example of React Router with Server Rendering
import RouterApp from '../ror-auto-load-components/RouterApp.server';

import PureComponent from '../ror-auto-load-components/PureComponent';
import CssModulesImagesFontsExample from '../ror-auto-load-components/CssModulesImagesFontsExample';

import SharedReduxStore from '../stores/SharedReduxStore';

// Deferred render on the client side w/ server render
import ManualRenderApp from '../ror-auto-load-components/ManualRenderApp.server';

// Deferred render on the client side w/ server render
import RenderedHtml from '../ror-auto-load-components/RenderedHtml.server';

// Deferred render on the client side w/ server render with additional HTML strings:
import ReactHelmetApp from '../ror-auto-load-components/ReactHelmetApp.server';

// Demonstrate using Images
import ImageExample from '../ror-auto-load-components/ImageExample';

import CacheDisabled from '../ror-auto-load-components/CacheDisabled';

import SetTimeoutLoggingApp from '../ror-auto-load-components/SetTimeoutLoggingApp.server';

import Loadable from '../ror-auto-load-components/Loadable.server';

import ApolloGraphQLApp from '../ror-auto-load-components/ApolloGraphQLApp.server';

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
  ApolloGraphQLApp,
});

ReactOnRails.registerStore({
  SharedReduxStore,
});
