import 'babel-polyfill';
import 'es5-shim';

import ReactOnRails from 'react-on-rails';

import MainPage from '../components/MainPage';
import MainPageWithLogAndThrow from '../components/MainPageWithLogAndThrow';
import MainPageES5 from '../components/MainPageES5';
import MainPageApp from './MainPageApp';

import ReduxApp from './ClientReduxApp';
import ReduxSharedStoreApp from './ClientReduxSharedStoreApp';
import RouterApp from './ClientRouterApp';
import PureComponent from '../components/PureComponent';
import CacheDisabled from '../components/CacheDisabled';
import CssModulesImagesFontsExample from '../components/CssModulesImagesFontsExample';
import ManualRenderApp from './ManualRenderAppRenderer';
import DeferredRenderApp from './DeferredRenderAppRenderer';

import SharedReduxStore from '../stores/SharedReduxStore';

// Deferred render on the client side w/ server render
import RenderedHtml from './ClientRenderedHtml';

// Deferred render on the client side w/ server render with additional HTML strings:
import ReactHelmetApp from './ReactHelmetClientApp';

// Demonstrate using Images
import ImageExample from '../components/ImageExample';

ReactOnRails.setOptions({
  traceTurbolinks: true,
});

ReactOnRails.register({
  MainPage,
  MainPageWithLogAndThrow,
  MainPageES5,
  ReduxApp,
  ReduxSharedStoreApp,
  MainPageApp,
  RouterApp,
  PureComponent,
  CssModulesImagesFontsExample,
  ManualRenderApp,
  DeferredRenderApp,
  CacheDisabled,
  RenderedHtml,
  ReactHelmetApp,
  ImageExample,
});

ReactOnRails.registerStore({
  SharedReduxStore,
});
