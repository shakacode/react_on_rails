import '../assets/styles/application.css';

import ReactOnRails from 'react-on-rails';

import HelloWorld from '../ror-auto-load-components/HelloWorld';

import HelloWorldWithLogAndThrow from '../ror-auto-load-components/HelloWorldWithLogAndThrow';
import HelloWorldES5 from '../ror-auto-load-components/HelloWorldES5';
import HelloWorldRehydratable from '../ror-auto-load-components/HelloWorldRehydratable';
import HelloWorldApp from '../ror-auto-load-components/HelloWorldApp';
import HelloWorldHooks from '../ror-auto-load-components/HelloWorldHooks';
import HelloWorldHooksContext from '../ror-auto-load-components/HelloWorldHooksContext';
import BrokenApp from '../ror-auto-load-components/BrokenApp';

import ReduxApp from '../ror-auto-load-components/ReduxApp.client';
import ReduxSharedStoreApp from '../ror-auto-load-components/ReduxSharedStoreApp.client';
import RouterApp from '../ror-auto-load-components/RouterApp.client';
import PureComponent from '../ror-auto-load-components/PureComponent';
import CacheDisabled from '../ror-auto-load-components/CacheDisabled';
import CssModulesImagesFontsExample from '../ror-auto-load-components/CssModulesImagesFontsExample';
import ManualRenderApp from '../ror-auto-load-components/ManualRenderApp';

import SharedReduxStore from '../stores/SharedReduxStore';

// Deferred render on the client side w/ server render
import RenderedHtml from '../ror-auto-load-components/RenderedHtml.client';

// Deferred render on the client side w/ server render with additional HTML strings:
import ReactHelmetApp from '../ror-auto-load-components/ReactHelmetApp.client';

// Demonstrate using Images
import ImageExample from '../ror-auto-load-components/ImageExample';

import SetTimeoutLoggingApp from '../ror-auto-load-components/SetTimeoutLoggingApp.client';

import Loadable from '../ror-auto-load-components/Loadable.client';

import ApolloGraphQLApp from '../ror-auto-load-components/ApolloGraphQLApp.client';

ReactOnRails.setOptions({
  traceTurbolinks: true,
});

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
  RouterApp,
  PureComponent,
  CssModulesImagesFontsExample,
  ManualRenderApp,
  CacheDisabled,
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
