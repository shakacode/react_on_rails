import HelloWorld from '../components/HelloWorld';
import HelloWorldWithLogAndThrow from '../components/HelloWorldWithLogAndThrow';
import HelloWorldES5 from '../components/HelloWorldES5';
import ReduxApp from './ClientReduxApp';
import HelloWorldApp from './HelloWorldApp';
import ClientRouterApp from './ClientRouterApp';

// This is an example of how to render a React component directly, without using Redux
window.HelloWorld = HelloWorld;
window.HelloWorldWithLogAndThrow = HelloWorldWithLogAndThrow;
window.HelloWorldES5 = HelloWorldES5;
window.ReduxApp = ReduxApp;
window.HelloWorldApp = HelloWorldApp;
window.RouterApp = ClientRouterApp;
