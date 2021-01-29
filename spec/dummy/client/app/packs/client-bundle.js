import 'core-js/stable';
import 'regenerator-runtime/runtime';
import 'jquery';
import 'jquery-ujs';

import ReactOnRails from 'react-on-rails';

import HelloWorld from '../components/HelloWorld';
import HelloWorldHooks from '../components/HelloWorldHooks';
import HelloWorldHooksContext from '../components/HelloWorldHooksContext';
import ContextFunctionReturnInvalidJSX from '../components/ContextFunctionReturnInvalidJSX';
import PureComponentWrappedInFunction from '../components/PureComponentWrappedInFunction';

import HelloWorldWithLogAndThrow from '../components/HelloWorldWithLogAndThrow';
import HelloWorldES5 from '../components/HelloWorldES5';
import HelloWorldRehydratable from '../components/HelloWorldRehydratable';
import HelloWorldApp from '../startup/HelloWorldApp';
import BrokenApp from '../startup/BrokenApp';

import ReduxApp from '../startup/ClientReduxApp';
import ReduxSharedStoreApp from '../startup/ClientReduxSharedStoreApp';
import RouterApp from '../startup/ClientRouterApp';
import PureComponent from '../components/PureComponent';
import CacheDisabled from '../components/CacheDisabled';
import CssModulesImagesFontsExample from '../components/CssModulesImagesFontsExample';
import ManualRenderApp from '../startup/ManualRenderAppRenderer';

import SharedReduxStore from '../stores/SharedReduxStore';

// Deferred render on the client side w/ server render
import RenderedHtml from '../startup/ClientRenderedHtml';

// Deferred render on the client side w/ server render with additional HTML strings:
import ReactHelmetApp from '../startup/ReactHelmetClientApp';

// Demonstrate using Images
import ImageExample from '../components/ImageExample';

import SetTimeoutLoggingApp from '../startup/SetTimeoutLoggingApp';
ReactOnRails.setOptions({
  traceTurbolinks: true,
});

ReactOnRails.register({
  BrokenApp,
  HelloWorld,
  HelloWorldWithLogAndThrow,
  HelloWorldES5,
  HelloWorldRehydratable,
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
  HelloWorldHooks,
  HelloWorldHooksContext,
  ContextFunctionReturnInvalidJSX,
  PureComponentWrappedInFunction,
});

ReactOnRails.registerStore({
  SharedReduxStore,
});
